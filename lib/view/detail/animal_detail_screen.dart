import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/model/animal_model.dart';
import '../../data/model/log_model.dart';
import '../../data/model/photo_model.dart';

import '../home/animal_add_screen.dart';
import 'widget/detail_widgets.dart';
import 'widget/qr_dialog.dart';
import 'widget/photo_view_screen.dart';
import 'widget/breeding_history_full_screen.dart'; // ★ 전체 기록 화면 import

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late Animal _currentAnimal;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _currentAnimal = widget.animal;
  }

  // [기능 0] 사진 업로드
  Future<void> _uploadGalleryPhoto() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final File file = File(pickedFile.path);
      final String fileName = "${const Uuid().v4()}.jpg";
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("animal_gallery/${_currentAnimal.id}/$fileName");

      await storageRef.putFile(file);
      final String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('animals')
          .doc(_currentAnimal.id)
          .collection('photos')
          .add({
        'photoUrl': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("사진이 앨범에 추가되었습니다.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("업로드 실패: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // [기능 1] 대표 사진 변경
  Future<void> _setProfilePhoto(String photoUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection('animals')
          .doc(_currentAnimal.id)
          .update({'photoUrl': photoUrl});

      setState(() {
        _currentAnimal = Animal(
          id: _currentAnimal.id,
          name: _currentAnimal.name,
          species: _currentAnimal.species,
          morph: _currentAnimal.morph,
          gender: _currentAnimal.gender,
          weight: _currentAnimal.weight,
          birthDate: _currentAnimal.birthDate,
          adoptDate: _currentAnimal.adoptDate,
          status: _currentAnimal.status,
          photoUrl: photoUrl,
        );
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("대표 사진이 변경되었습니다!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("변경 실패")));
    }
  }

  // [기능 2] 갤러리 사진 삭제
  Future<void> _deleteGalleryPhoto(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('animals')
          .doc(_currentAnimal.id)
          .collection('photos')
          .doc(docId)
          .delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _editAnimal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AnimalAddScreen(animal: _currentAnimal)),
    );
    final freshSnapshot = await FirebaseFirestore.instance
        .collection('animals')
        .doc(_currentAnimal.id)
        .get();
    if (freshSnapshot.exists && mounted) {
      setState(() {
        _currentAnimal =
            Animal.fromJson(freshSnapshot.data()!, freshSnapshot.id);
      });
    }
  }

  void _showAddLogDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController weightController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    bool isFeeding = false;
    bool isWeighing = false;
    bool isNote = false;
    String selectedFood = '귀뚜라미';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            scrollable: true,
            title: Text("${DateFormat('M월 d일').format(_selectedDay)} 기록"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("기존 기록이 있다면 덮어씌워집니다.",
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                const SizedBox(height: 10),
                CheckboxListTile(
                    title: const Text("🦗 먹이 급여"),
                    value: isFeeding,
                    activeColor: Colors.deepOrange,
                    onChanged: (v) => setDialogState(() => isFeeding = v!)),
                if (isFeeding) ...[
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(children: [
                        Wrap(
                            spacing: 8,
                            children: ['귀뚜라미', '밀웜', '슈퍼푸드', '기타'].map((food) {
                              return ChoiceChip(
                                  label: Text(food,
                                      style: const TextStyle(fontSize: 12)),
                                  selected: selectedFood == food,
                                  selectedColor: Colors.deepOrange.shade100,
                                  onSelected: (selected) {
                                    if (selected)
                                      setDialogState(() => selectedFood = food);
                                  });
                            }).toList()),
                        TextField(
                            controller: amountController,
                            decoration: const InputDecoration(
                                labelText: "급여량 (예: 2마리)", isDense: true)),
                        const SizedBox(height: 10)
                      ]))
                ],
                const Divider(),
                CheckboxListTile(
                    title: const Text("⚖️ 무게 측정"),
                    value: isWeighing,
                    activeColor: Colors.blue,
                    onChanged: (v) => setDialogState(() => isWeighing = v!)),
                if (isWeighing) ...[
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: "현재 무게 (g)",
                              suffixText: "g",
                              isDense: true)))
                ],
                const Divider(),
                CheckboxListTile(
                    title: const Text("📝 비고 (탈피 등)"),
                    value: isNote,
                    activeColor: Colors.green,
                    onChanged: (v) => setDialogState(() => isNote = v!)),
                if (isNote) ...[
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                          controller: noteController,
                          decoration: const InputDecoration(
                              labelText: "메모 내용",
                              hintText: "특이사항 입력",
                              isDense: true)))
                ]
              ],
            ),
            actions: [
              TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text("취소")),
              ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!isFeeding && !isWeighing && !isNote) return;
                          setDialogState(() => isSaving = true);
                          try {
                            final String docId =
                                DateFormat('yyyyMMdd').format(_selectedDay);
                            await FirebaseFirestore.instance
                                .collection('animals')
                                .doc(_currentAnimal.id)
                                .collection('logs')
                                .doc(docId)
                                .set({
                              'date': Timestamp.fromDate(_selectedDay),
                              if (isFeeding) 'foodType': selectedFood,
                              if (isFeeding)
                                'foodAmount': amountController.text,
                              if (isWeighing)
                                'weight':
                                    double.tryParse(weightController.text) ??
                                        0.0,
                              if (isNote) 'note': noteController.text,
                            }, SetOptions(merge: true));
                            if (isWeighing) {
                              final newWeight =
                                  double.tryParse(weightController.text) ?? 0.0;
                              if (newWeight > 0) {
                                await FirebaseFirestore.instance
                                    .collection('animals')
                                    .doc(_currentAnimal.id)
                                    .update({'weight': newWeight});
                                setState(
                                    () => _currentAnimal.weight = newWeight);
                              }
                            }
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("저장")),
            ],
          );
        },
      ),
    );
  }

  void _showQrCode() {
    showDialog(
        context: context,
        builder: (context) => QrDialog(
            animalName: _currentAnimal.name,
            animalId: _currentAnimal.id ?? "error"));
  }

  void _deleteAnimal() async {
    bool? confirm = await showDialog(
        context: context,
        builder: (ctx) =>
            AlertDialog(title: const Text("정말 삭제하시겠습니까?"), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("취소")),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("삭제", style: TextStyle(color: Colors.red)))
            ]));
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('animals')
          .doc(_currentAnimal.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMale = _currentAnimal.gender == 'Male';
    final genderColor = isMale
        ? Colors.blueAccent
        : (_currentAnimal.gender == 'Female' ? Colors.pinkAccent : Colors.grey);
    final genderIcon = isMale ? Icons.male : Icons.female;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320.0,
              pinned: true,
              backgroundColor: Colors.deepOrange,
              actions: [
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: _editAnimal),
                IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: _deleteAnimal),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: _currentAnimal.id ?? 'hero',
                  child: _currentAnimal.photoUrl != null
                      ? Image.network(_currentAnimal.photoUrl!,
                          fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.pets,
                              size: 80, color: Colors.white)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. 네임텍
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          DetailBadge(
                              text: _currentAnimal.name,
                              color: Colors.deepOrange,
                              icon: Icons.pets),
                          const SizedBox(width: 8),
                          DetailBadge(
                              text: _currentAnimal.gender,
                              color: genderColor,
                              icon: genderIcon),
                          const SizedBox(width: 8),
                          DetailBadge(
                              text: _currentAnimal.status,
                              color: Colors.orange,
                              icon: Icons.star),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. 정보 카드
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(children: [
                        DetailInfoRow(
                            icon: Icons.category,
                            title: "Species",
                            value: _currentAnimal.species),
                        const Divider(height: 30, thickness: 0.5),
                        DetailInfoRow(
                            icon: Icons.palette,
                            title: "Morph",
                            value: _currentAnimal.morph),
                        const Divider(height: 30, thickness: 0.5),
                        DetailInfoRow(
                            icon: Icons.monitor_weight,
                            title: "Weight",
                            value: "${_currentAnimal.weight}g")
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // 3. History
                    const Text("  History",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(children: [
                        DetailDateRow(
                            title: "Hatching",
                            date: _currentAnimal.birthDate,
                            icon: Icons.cake),
                        const SizedBox(height: 20),
                        DetailDateRow(
                            title: "Adoption",
                            date: _currentAnimal.adoptDate,
                            icon: Icons.home)
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ★ 4. [New] 브리딩 이력 버튼 (수정됨)
                    _buildBreedingHistory(),
                    const SizedBox(height: 24),

                    // 5. 캘린더
                    _buildUnifiedCalendar(),
                    const SizedBox(height: 24),

                    // 6. 성장 앨범
                    _buildGallerySection(),

                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                        onPressed: _showQrCode,
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text("QR 코드 확인"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)))),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★ 브리딩 이력 버튼 (리스트 -> 버튼 형태로 변경됨)
  Widget _buildBreedingHistory() {
    // 성별이 명확하지 않으면(Unknown) 안 보여줌
    if (_currentAnimal.gender != 'Male' && _currentAnimal.gender != 'Female') {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        // 아이콘 (빨간 하트)
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite, color: Colors.redAccent, size: 24),
        ),
        // 제목
        title: const Text(
          "Breeding History",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        // 설명
        subtitle: Text(
          "이 개체의 브리딩/산란 기록 보기",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        // 화살표
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),

        // ★ 클릭 시 전체 리스트 화면으로 이동
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BreedingHistoryFullScreen(animal: _currentAnimal),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("  Growth Album",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54)),
              _isUploadingPhoto
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      onPressed: _uploadGalleryPhoto,
                      icon: const Icon(Icons.add_a_photo,
                          color: Colors.deepOrange),
                      tooltip: "사진 추가",
                    ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('animals')
                .doc(_currentAnimal.id)
                .collection('photos')
                .orderBy('uploadedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("오류"));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Center(
                      child: Text("사진을 추가해보세요!",
                          style: TextStyle(color: Colors.grey.shade400))),
                );
              }
              final docs = snapshot.data!.docs;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                itemCount: docs.length,
                separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final photoData = PhotoModel.fromJson(
                      docs[index].data() as Map<String, dynamic>,
                      docs[index].id);
                  final String dateStr =
                      DateFormat('yy.MM.dd').format(photoData.uploadedAt);
                  return GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                  leading: const Icon(Icons.fullscreen),
                                  title: const Text('크게 보기'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PhotoViewScreen(
                                                    photoUrl:
                                                        photoData.photoUrl)));
                                  }),
                              ListTile(
                                  leading: const Icon(Icons.photo_camera_front,
                                      color: Colors.deepOrange),
                                  title: const Text('대표 사진으로 설정'),
                                  onTap: () {
                                    _setProfilePhoto(photoData.photoUrl);
                                  }),
                              ListTile(
                                  leading: const Icon(Icons.delete,
                                      color: Colors.red),
                                  title: const Text('삭제'),
                                  textColor: Colors.red,
                                  onTap: () {
                                    _deleteGalleryPhoto(docs[index].id);
                                  }),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                                imageUrl: photoData.photoUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.grey.shade200),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error))),
                        Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(16))),
                                child: Text(dateStr,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedCalendar() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('animals')
            .doc(_currentAnimal.id)
            .collection('logs')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const SizedBox(
                height: 300, child: Center(child: CircularProgressIndicator()));
          final docs = snapshot.data!.docs;
          final logs = docs
              .map((doc) => LogRecord.fromJson(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          final selectedLogs =
              logs.where((log) => isSameDay(log.date, _selectedDay)).toList();

          return Column(
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Care Calendar",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                            onPressed: _showAddLogDialog,
                            icon: const Icon(Icons.add_circle,
                                color: Colors.deepOrange, size: 32),
                            tooltip: "기록 추가")
                      ])),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                availableGestures: AvailableGestures.horizontalSwipe,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders:
                    CalendarBuilders(markerBuilder: (context, date, events) {
                  final dayLogs =
                      logs.where((log) => isSameDay(log.date, date)).toList();
                  if (dayLogs.isEmpty) return null;
                  bool hasFood = dayLogs.any((log) => log.foodType != null);
                  bool hasWeight = dayLogs.any((log) => log.weight != null);
                  bool hasNote = dayLogs.any((log) => log.note != null);
                  return Positioned(
                      bottom: 1,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (hasFood)
                          const Icon(Icons.bug_report,
                              size: 12, color: Colors.deepOrange),
                        if (hasWeight)
                          const Icon(Icons.scale, size: 12, color: Colors.blue),
                        if (hasNote)
                          const Icon(Icons.edit_note,
                              size: 12, color: Colors.green)
                      ]));
                }),
                headerStyle: const HeaderStyle(
                    formatButtonVisible: false, titleCentered: true),
                calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                        color: Colors.orangeAccent, shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(
                        color: Colors.deepOrange, shape: BoxShape.circle)),
              ),
              const Divider(),
              if (selectedLogs.isEmpty)
                Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(children: [
                      Text("${DateFormat('M월 d일').format(_selectedDay)} 기록 없음",
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("우측 상단 + 버튼을 눌러 기록하세요.",
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12))
                    ]))
              else
                ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedLogs.length,
                    separatorBuilder: (ctx, idx) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = selectedLogs[index];
                      return ListTile(
                          title: Row(children: [
                            if (log.foodType != null) ...[
                              const Icon(Icons.bug_report,
                                  size: 16, color: Colors.deepOrange),
                              const SizedBox(width: 4),
                              Text("${log.foodType} ${log.foodAmount}  ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))
                            ],
                            if (log.weight != null) ...[
                              const Icon(Icons.scale,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text("${log.weight}g  ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))
                            ]
                          ]),
                          subtitle: log.note != null && log.note!.isNotEmpty
                              ? Text("📝 ${log.note!}",
                                  style: const TextStyle(color: Colors.black87))
                              : null);
                    }),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
