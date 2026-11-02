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

            Thread.Sleep(1000); // Allow Windows file handles to release

            string backupDir = Path.Combine(Path.GetTempPath(), "SirfBill_Backup_" + DateTime.Now.Ticks);
            string stagingDir = Path.Combine(Path.GetTempPath(), "SirfBill_Staging_" + DateTime.Now.Ticks);

            try
            {
                // Step 2: Extract update package to staging
                Console.WriteLine("Extracting update files...");
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
                Console.WriteLine("Backing up current version...");
                Directory.CreateDirectory(backupDir);
                CopyDirectory(installDir, backupDir, excludeUpdater: true);

                // Step 4: Replace app files (preserving local configs/database)
                Console.WriteLine("Applying update files...");
                CopyDirectory(sourceDir, installDir, excludeUpdater: true);

                Console.WriteLine("Update applied successfully!");

                // Step 5: Clean up package
                try { File.Delete(packagePath); } catch { }
                try { Directory.Delete(stagingDir, true); } catch { }

                // Step 6: Launch new version
                if (!string.IsNullOrEmpty(restartExe) && File.Exists(restartExe))
                {
                    Console.WriteLine("Restarting SirfBill...");
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = restartExe,
                        UseShellExecute = true
                    });
                }

                return 0;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error during update: {ex.Message}");
                Console.WriteLine("Rolling back previous version...");

                // Rollback from backup
                try
                {
                    if (Directory.Exists(backupDir))
                    {
                        CopyDirectory(backupDir, installDir, excludeUpdater: true);
                        Console.WriteLine("Rollback completed.");
                    }
                }
                catch (Exception rollbackEx)
                {
                    Console.WriteLine($"Rollback error: {rollbackEx.Message}");
                }

                return 1;
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
                File.Copy(file, destFile, true);
            }

            foreach (var directory in Directory.GetDirectories(sourceDir))
            {
                string dirName = Path.GetFileName(directory);
                CopyDirectory(directory, Path.Combine(targetDir, dirName), excludeUpdater);
            }
        }
    }
}
