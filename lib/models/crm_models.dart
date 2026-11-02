class CrmPatient {
  final String id;
  final String name;
  final String uhid;
  final String phone;
  final String email;
  final String address;
  final int age;
  final String gender;
  final String bloodGroup;
  final DateTime lastVisit;
  final String status;
  final String? avatarUrl;

  CrmPatient({
    required this.id,
    required this.name,
    required this.uhid,
    required this.phone,
    required this.email,
    required this.address,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.lastVisit,
    required this.status,
    this.avatarUrl,
  });
}

class CrmNote {
  final String id;
  final String patientId;
  final String note;
  final String author;
  final DateTime createdAt;

  CrmNote({
    required this.id,
    required this.patientId,
    required this.note,
    required this.author,
    required this.createdAt,
  });
}

class CrmAppointment {
  final String id;
  final String patientName;
  final String patientAge;
  final String patientGender;
  final String patientPhone;
  final String patientEmail;
  final String location;
  final String doctorName;
  final String appointmentType;
  final String time;
  final String date;
  final String status;
  final String consultationFee;
  final String paymentStatus;
  final String notes;

  CrmAppointment({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientPhone,
    required this.patientEmail,
    required this.location,
    required this.doctorName,
    required this.appointmentType,
    required this.time,
    required this.date,
    required this.status,
    required this.consultationFee,
    required this.paymentStatus,
    required this.notes,
  });
}

class CrmMedicine {
  final String name;
  final String dose;
  final String frequency;
  final String duration;
  final String instruction;

  CrmMedicine({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
    required this.instruction,
  });
}

class CrmDoctor {
  final String id;
  final String name;
  final String specialization;
  final String phone;
  final String email;
  final String consultationFee;
  final String availabilityDays;
  final String availabilityTime;
  final String status;
  final String avatarUrl;

  CrmDoctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.phone,
    required this.email,
    required this.consultationFee,
    required this.availabilityDays,
    required this.availabilityTime,
    required this.status,
    required this.avatarUrl,
  });
}

class CrmReceiptItem {
  final String particulars;
  final int qty;
  final double unitPrice;
  final double amount;

  CrmReceiptItem({
    required this.particulars,
    required this.qty,
    required this.unitPrice,
    required this.amount,
  });
}

class CrmLabTest {
  final String name;
  final String code;
  final String sampleType;
  final double price;

  CrmLabTest({
    required this.name,
    required this.code,
    required this.sampleType,
    required this.price,
  });
}

class CrmOrderItem {
  final String name;
  final int qty;
  final double unitPrice;
  final double amount;

  CrmOrderItem({
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.amount,
  });
}

class CrmOrder {
  final String id;
  final String date;
  final String time;
  final String patientName;
  final String itemsCount;
  final double total;
  final String status;
  final String source;
  final List<CrmOrderItem> items;
  final String? tenantId;

  CrmOrder({
    required this.id,
    required this.date,
    required this.time,
    required this.patientName,
    required this.itemsCount,
    required this.total,
    required this.status,
    required this.source,
    required this.items,
    this.tenantId,
  });
}
