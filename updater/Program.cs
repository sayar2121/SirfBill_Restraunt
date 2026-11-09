using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Threading;

namespace SirfBill.Updater
{
    class Program
    {
        static int Main(string[] args)
        {
            Console.WriteLine("=======================================");
            Console.WriteLine("       SirfBill Windows Updater        ");
            Console.WriteLine("=======================================");

            int waitPid = -1;
            string installDir = "";
            string packagePath = "";
            string restartExe = "";

            for (int i = 0; i < args.Length; i++)
            {
                if (args[i] == "--wait-pid" && i + 1 < args.Length)
                    int.TryParse(args[++i], out waitPid);
                else if (args[i] == "--install-dir" && i + 1 < args.Length)
                    installDir = args[++i];
                else if (args[i] == "--package" && i + 1 < args.Length)
                    packagePath = args[++i];
                else if (args[i] == "--restart-exe" && i + 1 < args.Length)
                    restartExe = args[++i];
            }

            if (string.IsNullOrEmpty(installDir) || string.IsNullOrEmpty(packagePath))
            {
                Console.WriteLine("Missing required arguments.");
                return 1;
            }

            // Check write permission to install directory. If denied, elevate via UAC.
            if (!HasWritePermission(installDir))
            {
                Console.WriteLine("Write permission to installDir denied. Requesting administrator privileges...");
                try
                {
                    string procPath = Environment.ProcessPath ?? Process.GetCurrentProcess().MainModule?.FileName ?? "updater.exe";
                    var startInfo = new ProcessStartInfo
                    {
                        FileName = procPath,
                        UseShellExecute = true,
                        Verb = "runas"
                    };

                    for (int i = 0; i < args.Length; i++)
                    {
                        startInfo.ArgumentList.Add(args[i]);
                    }

                    Process.Start(startInfo);
                    return 0; // Elevated process takes over
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Elevation request failed: {ex.Message}");
                }
            }

            // Step 1: Wait for parent process to exit
            if (waitPid > 0)
            {
                try
                {
                    var parentProcess = Process.GetProcessById(waitPid);
                    Console.WriteLine($"Waiting for SirfBill process (PID: {waitPid}) to exit...");
                    parentProcess.WaitForExit(15000); // 15 seconds timeout
                }
                catch
                {
                    // Process already exited
                }
            }

            // Also terminate any lingering app process so files are not locked
            if (!string.IsNullOrEmpty(restartExe))
            {
                try
                {
                    string procName = Path.GetFileNameWithoutExtension(restartExe);
                    foreach (var p in Process.GetProcessesByName(procName))
                    {
                        try
                        {
                            if (p.Id != Environment.ProcessId && !p.HasExited)
                            {
                                p.Kill();
                                p.WaitForExit(2000);
                            }
                        }
                        catch { }
                    }
                }
                catch { }
            }

            Thread.Sleep(1000); // Allow Windows file handles to release

            string backupDir = Path.Combine(Path.GetTempPath(), "SirfBill_Backup_" + DateTime.Now.Ticks);
            string stagingDir = Path.Combine(Path.GetTempPath(), "SirfBill_Staging_" + DateTime.Now.Ticks);
            string logPath = Path.Combine(installDir, "updater.log");
            string tempLogPath = Path.Combine(Path.GetTempPath(), "sirfbill_updater.log");

            void Log(string message)
            {
                try
                {
                    string entry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}\n";
                    try { File.AppendAllText(logPath, entry); } catch { }
                    try { File.AppendAllText(tempLogPath, entry); } catch { }
                    Console.WriteLine(message);
                }
                catch { }
            }

            try
            {
                Log($"Updater started for PID={waitPid}, installDir='{installDir}', restartExe='{restartExe}'");

                // Step 2: Extract update package to staging
                Log("Extracting update files...");
                Directory.CreateDirectory(stagingDir);
                ZipFile.ExtractToDirectory(packagePath, stagingDir);

                // Check if extracted directory has an internal folder (e.g. Release or SirfBill)
                string sourceDir = stagingDir;
                var subDirs = Directory.GetDirectories(stagingDir);
                if (subDirs.Length == 1 && Directory.GetFiles(stagingDir).Length == 0)
                {
                    sourceDir = subDirs[0];
                }

                // Step 3: Backup current install directory
                Log("Backing up current version...");
                Directory.CreateDirectory(backupDir);
                CopyDirectory(installDir, backupDir, excludeUpdater: true);

                // Step 4: Replace app files (preserving local configs/database)
                Log("Applying update files...");
                CopyDirectory(sourceDir, installDir, excludeUpdater: true);

                Log("Update applied successfully!");

                // Step 5: Clean up package
                try { File.Delete(packagePath); } catch { }
                try { Directory.Delete(stagingDir, true); } catch { }

                // Step 6: Launch new version
                if (!string.IsNullOrEmpty(restartExe) && File.Exists(restartExe))
                {
                    Log("Restarting SirfBill...");
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = restartExe,
                        WorkingDirectory = installDir,
                        UseShellExecute = true
                    });
                }

                return 0;
            }
            catch (Exception ex)
            {
                Log($"Error during update: {ex.Message}");
                Log($"Stack trace: {ex.StackTrace}");
                Log("Rolling back previous version...");

                // Rollback from backup
                try
                {
                    if (Directory.Exists(backupDir))
                    {
                        CopyDirectory(backupDir, installDir, excludeUpdater: true);
                        Log("Rollback completed.");
                    }
                }
                catch (Exception rollbackEx)
                {
                    Log($"Rollback error: {rollbackEx.Message}");
                }

                // If update failed and rolled back, still restart original app so user isn't stranded
                if (!string.IsNullOrEmpty(restartExe) && File.Exists(restartExe))
                {
                    try
                    {
                        Process.Start(new ProcessStartInfo
                        {
                            FileName = restartExe,
                            WorkingDirectory = installDir,
                            UseShellExecute = true
                        });
                    }
                    catch { }
                }

                return 1;
            }
        }

        static bool HasWritePermission(string dir)
        {
            if (string.IsNullOrEmpty(dir) || !Directory.Exists(dir))
                return false;

            try
            {
                string testFile = Path.Combine(dir, ".perm_test_" + Guid.NewGuid().ToString("N"));
                File.WriteAllText(testFile, "test");
                File.Delete(testFile);
                return true;
            }
            catch
            {
                return false;
            }
        }

        static void CopyDirectory(string sourceDir, string targetDir, bool excludeUpdater = false)
        {
            Directory.CreateDirectory(targetDir);

            foreach (var file in Directory.GetFiles(sourceDir))
            {
                string fileName = Path.GetFileName(file);
                if (excludeUpdater && fileName.Equals("updater.exe", StringComparison.OrdinalIgnoreCase))
                    continue;

                // Preserve local env files if not overwritten
                if (fileName.Equals(".env", StringComparison.OrdinalIgnoreCase) && File.Exists(Path.Combine(targetDir, fileName)))
                    continue;

                string destFile = Path.Combine(targetDir, fileName);
                CopyFileWithRetry(file, destFile);
            }

            foreach (var directory in Directory.GetDirectories(sourceDir))
            {
                string dirName = Path.GetFileName(directory);
                CopyDirectory(directory, Path.Combine(targetDir, dirName), excludeUpdater);
            }
        }

        static void CopyFileWithRetry(string source, string dest, int maxRetries = 5)
        {
            for (int i = 0; i < maxRetries; i++)
            {
                try
                {
                    File.Copy(source, dest, true);
                    return;
                }
                catch (IOException) when (i < maxRetries - 1)
                {
                    Thread.Sleep(500);
                }
            }
            File.Copy(source, dest, true);
        }
    }
}
