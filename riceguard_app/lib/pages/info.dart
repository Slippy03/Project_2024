import 'package:flutter/material.dart';

class infopage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'องค์ความรู้โรคใบข้าว',
      theme: ThemeData(primarySwatch: Colors.green),
      home: DiseaseListPage(),
    );
  }
}

class Disease {
  final String name;
  final String imageUrl;
  final String found;
  final String cause;
  final String symptoms;
  final String treatment;

  Disease({
    required this.name,
    required this.imageUrl,
    required this.found,
    required this.cause,
    required this.symptoms,
    required this.treatment,
  });
}

final List<Disease> diseases = [
  Disease(
    name: 'โรคใบขีดสีน้ำตาล',
    imageUrl: 'assets/narrow_brown_spot.jpg',
    found: 'พบมากทั้งนาน้ำฝนและนาชลประทานในทุกภาคของไทย โดยเฉพาะช่วงข้าวแตกกอ',
    cause: 'เชื้อรา Cercospora oryzae',
    symptoms:
        'แผลที่ใบมีสีน้ำตาลเป็นขีดขนานกับเส้นใบ พบมากที่ใบล่างและปลายใบ ใบแห้งตายจากปลายใบก่อน',
    treatment:
        'ใช้สารป้องกันกำจัดเชื้อรา เช่น แมนโคเซบ และดูแลสภาพแวดล้อมให้โปร่งไม่ชื้นเกินไป',
  ),
  Disease(
    name: 'โรคใบวงสีน้ำตาล',
    imageUrl: 'assets/leaf_scald.jpg',
    found: 'พบในข้าวไร่ภาคเหนือและภาคใต้ และนาปีภาคตะวันออกเฉียงเหนือ',
    cause: 'เชื้อรา Rhynocosporium oryzae',
    symptoms:
        'แผลที่ปลายใบเป็นรอยช้ำรูปไข่สีน้ำตาลปนเทา ขอบแผลสีน้ำตาลอ่อน ลุกลามเป็นวงซ้อนกันจนใบแห้งก่อนกำหนด',
    treatment:
        'ปรับลดการใส่ปุ๋ยไนโตรเจน และใช้สารป้องกันกำจัดเชื้อราเมื่อพบโรคระบาด',
  ),
  Disease(
    name: 'โรคไหม้',
    imageUrl: 'assets/blast.jpg',
    found: 'พบในข้าวนาสวน นาปี นาปรัง และข้าวไร่ ทั่วทุกภาคของไทย',
    cause: 'เชื้อรา Pyricularia oryzae',
    symptoms:
        'แผลจุดสีน้ำตาลตรงกลางเทา รูปตา ความยาวประมาณ 10-15 มม. ลุกลามได้ทั้งใบ คอรวง และข้อต่อใบ',
    treatment:
        'ใช้พันธุ์ต้านทานและฉีดพ่นสารป้องกันกำจัดเชื้อรา เช่น ไตรไซโคลาโซล โดยเฉพาะช่วงอากาศเย็นและชื้น',
  ),
  Disease(
    name: 'โรคใบสีส้ม',
    imageUrl: 'assets/tungro.jpg',
    found: 'พบมากในนาชลประทานภาคกลางและภาคเหนือตอนล่าง',
    cause: 'ไวรัส RTBV และ RTSV',
    symptoms:
        'ใบเริ่มมีสีเหลืองสลับเขียว ก่อนเปลี่ยนเป็นสีเหลืองถึงส้ม ต้นเตี้ย แคระแกรน ใบใหม่เติบโตช้า ออกรวงเล็กหรือไม่ออกรวง',
    treatment: 'ควบคุมแมลงพาหะ เช่น เพลี้ยจักจั่นเขียว และปลูกพันธุ์ต้านทาน',
  ),
  Disease(
    name: 'โรคกาบใบแห้ง',
    imageUrl: 'assets/sheath_blight.jpg',
    found:
        'พบในนาชลประทานภาคกลาง ภาคเหนือ และภาคใต้ โดยเฉพาะในแปลงที่ข้าวแตกกอหนาแน่น',
    cause: 'เชื้อรา Rhizoctonia solani',
    symptoms:
        'แผลสีเขียวปนเทาที่กาบใบล่าง ขนาด 1-4x2-10 มม. แผลลุกลามขึ้นใบและใบธง ทำให้ใบแห้งและลดผลผลิต',
    treatment:
        'ลดความหนาแน่นของต้นข้าว และพ่นสารป้องกันเชื้อรา เช่น คาซูกามัยซิน',
  ),
];

class DiseaseListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('องค์ความรู้โรคใบข้าว')),
      body: ListView.builder(
        itemCount: diseases.length,
        itemBuilder: (context, index) {
          final disease = diseases[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: Image.asset(disease.imageUrl,
                  width: 60, height: 60, fit: BoxFit.cover),
              title: Text(disease.name),
              subtitle: Text(disease.symptoms),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiseaseDetailPage(disease: disease),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DiseaseDetailPage extends StatelessWidget {
  final Disease disease;

  const DiseaseDetailPage({Key? key, required this.disease}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(disease.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.asset(disease.imageUrl, fit: BoxFit.cover),
            SizedBox(height: 16),
            Text('พบมากในพื้นที่:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(disease.found),
            SizedBox(height: 8),
            Text('สาเหตุ:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(disease.cause),
            SizedBox(height: 8),
            Text('ลักษณะอาการ:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(disease.symptoms),
            SizedBox(height: 8),
            Text('แนวทางการรักษา:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(disease.treatment),
          ],
        ),
      ),
    );
  }
}
