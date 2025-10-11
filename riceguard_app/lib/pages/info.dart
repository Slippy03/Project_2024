import 'package:flutter/material.dart';

class infopage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DiseaseListPage();
  }
}

class Disease {
  final String name;
  final String englishName;
  final String imageUrl;
  final String found;
  final String cause;
  final String symptoms;
  final String treatment;
  final String prevention;
  final String severity;
  final Color severityColor;
  final List<String> affectedAreas;
  final String season;
  final String economicImpact;

  Disease({
    required this.name,
    required this.englishName,
    required this.imageUrl,
    required this.found,
    required this.cause,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
    required this.severity,
    required this.severityColor,
    required this.affectedAreas,
    required this.season,
    required this.economicImpact,
  });
}

final List<Disease> diseases = [
  Disease(
    name: 'โรคใบวงสีน้ำตาล',
    englishName: 'Leaf Scald',
    imageUrl: 'assets/leaf_scald.jpg',
    found: 'พบในข้าวไร่ภาคเหนือและภาคใต้ และนาปีภาคตะวันออกเฉียงเหนือ',
    cause: 'เชื้อรา Rhynchosporium oryzae',
    symptoms:
        'แผลที่ปลายใบเป็นรอยช้ำรูปไข่สีน้ำตาลปนเทา ขอบแผลสีน้ำตาลอ่อน ลุกลามเป็นวงซ้อนกันจนใบแห้งก่อนกำหนด อาจมีจุดสีดำเล็กๆ',
    treatment:
        'พ่นสารป้องกันกำจัดเชื้อรา เช่น โปรพิโคนาโซล 25% EC อัตรา 20 มล./น้ำ 20 ลิตร หรือ เทบูโคนาโซล 25% WG อัตรา 20 กรัม/น้ำ 20 ลิตร',
    prevention:
        '• ปรับลดการใส่ปุ๋ยไนโตรเจน\n• ปลูกพันธุ์ต้านทาน\n• ระบายน้ำให้ดี\n• หลีกเลี่ยงการปลูกหนาแน่นเกินไป',
    severity: 'สูง',
    severityColor: Colors.red,
    affectedAreas: ['ภาคเหนือ', 'ภาคตะวันออกเฉียงเหนือ', 'ภาคใต้'],
    season: 'ฤดูฝน - ฤดูหนาว',
    economicImpact: 'สูญเสียผลผลิต 20-50% ในพื้นที่ระบาดหนัก',
  ),
  Disease(
    name: 'โรคไหม้',
    englishName: 'Rice Blast',
    imageUrl: 'assets/blast.jpg',
    found: 'พบในข้าวนาสวน นาปี นาปรัง และข้าวไร่ ทั่วทุกภาคของไทย',
    cause: 'เชื้อรา Pyricularia oryzae (Magnaporthe oryzae)',
    symptoms:
        'แผลจุดสีน้ำตาลตรงกลางเทา รูปตา ความยาวประมาณ 10-15 มม. ลุกลามได้ทั้งใบ คอรวง และข้อต่อใบ มีขอบสีน้ำตาลเข้ม',
    treatment:
        'พ่นสารป้องกันกำจัดเชื้อรา เช่น ไตรไซโคลาโซล 75% WG อัตรา 6 กรัม/น้ำ 20 ลิตร หรือ อิโซโปรไทโอลาเนต 40% SC อัตรา 25 มล./น้ำ 20 ลิตร',
    prevention:
        '• ใช้พันธุ์ต้านทาน\n• หลีกเลี่ยงการใส่ปุ๋ยไนโตรเจนมากเกินไป\n• ระบายน้ำให้ดี\n• ปลูกในระยะที่เหมาะสม',
    severity: 'สูงมาก',
    severityColor: Colors.red[800]!,
    affectedAreas: ['ทุกภาคของไทย'],
    season: 'ตลอดปี (รุนแรงในฤดูฝน)',
    economicImpact: 'สูญเสียผลผลิต 30-70% หากไม่ได้รับการรักษา',
  ),
  Disease(
    name: 'โรคใบสีส้ม',
    englishName: 'Rice Tungro Disease',
    imageUrl: 'assets/tungro.jpg',
    found: 'พบมากในนาชลประทานภาคกลางและภาคเหนือตอนล่าง',
    cause:
        'ไวรัส RTBV (Rice tungro bacilliform virus) และ RTSV (Rice tungro spherical virus)',
    symptoms:
        'ใบเริ่มมีสีเหลืองสลับเขียว ก่อนเปลี่ยนเป็นสีเหลืองถึงส้ม ต้นเตี้ย แคระแกรน ใบใหม่เติบโตช้า ออกรวงเล็กหรือไม่ออกรวง เมล็ดลีบ',
    treatment:
        'ไม่มีการรักษาโดยตรง ต้องควบคุมแมลงพาหะ เช่น เพลี้ยจักจั่นเขียว ด้วยสารฆ่าแมลง เช่น อิมิดาโคลพริด 20% SL อัตรา 25 มล./น้ำ 20 ลิตร',
    prevention:
        '• ปลูกพันธุ์ต้านทาน\n• ควบคุมเพลี้ยจักจั่นเขียว\n• หลีกเลี่ยงการปลูกข้าวต่อเนื่อง\n• ไถกลบตอซัง',
    severity: 'สูงมาก',
    severityColor: Colors.red[900]!,
    affectedAreas: ['ภาคกลาง', 'ภาคเหนือตอนล่าง'],
    season: 'ฤดูฝน - ต้นฤดูหนาว',
    economicImpact: 'สูญเสียผลผลิต 50-100% ในพื้นที่ระบาดหนัก',
  ),
  Disease(
    name: 'โรคกาบใบแห้ง',
    englishName: 'Sheath Blight',
    imageUrl: 'assets/sheath_blight.jpg',
    found:
        'พบในนาชลประทานภาคกลาง ภาคเหนือ และภาคใต้ โดยเฉพาะในแปลงที่ข้าวแตกกอหนาแน่น',
    cause: 'เชื้อรา Rhizoctonia solani',
    symptoms:
        'แผลสีเขียวปนเทาที่กาบใบล่าง ขนาด 1-4x2-10 มม. แผลลุกลามขึ้นใบและใบธง ทำให้ใบแห้งและลดผลผลิต มีขอบแผลสีน้ำตาลเข้ม',
    treatment:
        'พ่นสารป้องกันเชื้อรา เช่น คาซูกามัยซิน 3% SL อัตรา 30 มล./น้ำ 20 ลิตร หรือ ฟลูโตลานิล 20% SC อัตรา 50 มล./น้ำ 20 ลิตร',
    prevention:
        '• ลดความหนาแน่นของต้นข้าว\n• ระบายน้ำให้ดี\n• หลีกเลี่ยงการใส่ปุ๋ยไนโตรเจนมากเกินไป\n• เก็บเศษซากพืช',
    severity: 'ปานกลาง',
    severityColor: Colors.orange[700]!,
    affectedAreas: ['ภาคกลาง', 'ภาคเหนือ', 'ภาคใต้'],
    season: 'ฤดูฝน - ต้นฤดูหนาว',
    economicImpact: 'สูญเสียผลผลิต 15-40% ในพื้นที่ระบาดหนัก',
  ),
  Disease(
    name: 'โรคใบจุดสีน้ำตาล',
    englishName: 'Brown Spot',
    imageUrl: 'assets/brown_spot.jpg',
    found: 'พบทั่วไปในทุกภาคของไทย โดยเฉพาะในพื้นที่ที่มีการขาดแคลนธาตุอาหาร',
    cause: 'เชื้อรา Bipolaris oryzae (Cochliobolus miyabeanus)',
    symptoms:
        'จุดสีน้ำตาลรูปวงรี ขนาด 4-10 มม. มีขอบสีเหลือง ตรงกลางสีเทาอ่อน พบได้ทั้งใบ กาบใบ และเมล็ด',
    treatment:
        'พ่นสารป้องกันกำจัดเชื้อรา เช่น แมนโคเซบ 80% WP อัตรา 25 กรัม/น้ำ 20 ลิตร หรือ คาร์เบนดาซิม 50% WP อัตรา 20 กรัม/น้ำ 20 ลิตร',
    prevention:
        '• ใส่ปุ๋ยครบถ้วน โดยเฉพาะโพแทสเซียม\n• ใช้เมล็ดพันธุ์สะอาด\n• ระบายน้ำให้ดี\n• หลีกเลี่ยงความเครียดจากภัยแล้ง',
    severity: 'ปานกลาง',
    severityColor: Colors.orange[600]!,
    affectedAreas: ['ทุกภาคของไทย'],
    season: 'ฤดูแล้ง - ต้นฤดูฝน',
    economicImpact: 'สูญเสียผลผลิต 10-25% หากไม่ได้รับการรักษา',
  ),
];

class DiseaseListPage extends StatefulWidget {
  @override
  _DiseaseListPageState createState() => _DiseaseListPageState();
}

class _DiseaseListPageState extends State<DiseaseListPage> {
  String selectedSeverity = 'ทั้งหมด';

  @override
  Widget build(BuildContext context) {
    final filteredDiseases = diseases.where((disease) {
      final matchesSeverity =
          selectedSeverity == 'ทั้งหมด' || disease.severity == selectedSeverity;
      return matchesSeverity;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book, // หรือ Icons.library_books
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'องค์ความรู้โรคใบข้าว',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Column(
              children: [
                SizedBox(height: 15),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['ทั้งหมด', 'ปานกลาง', 'สูง', 'สูงมาก'].map((severity) {
                      return Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: FilterChip(
                          label: Text(severity),
                          selected: selectedSeverity == severity,
                          onSelected: (selected) =>
                              setState(() => selectedSeverity = severity),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedSeverity == severity
                                ? Colors.green[600]
                                : const Color.fromARGB(255, 75, 73, 73),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Disease Count
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.eco, color: Colors.green[600]),
                SizedBox(width: 10),
                Text(
                  'พบ ${filteredDiseases.length} โรค',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          // Disease List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredDiseases.length,
              itemBuilder: (context, index) {
                final disease = filteredDiseases[index];
                return _buildDiseaseCard(context, disease);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(BuildContext context, Disease disease) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DiseaseDetailPage(disease: disease)),
        ),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              // Disease Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(disease.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 15),
              // Disease Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease.name,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      disease.englishName,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: disease.severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: disease.severityColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'ระดับ: ${disease.severity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: disease.severityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      disease.season,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
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
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.green[600],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                disease.name,
                style: TextStyle(fontWeight: FontWeight.bold, shadows: [
                  Shadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      offset: Offset(1, 1))
                ]),
              ),
              background: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(disease.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  _buildHeaderCard(),
                  SizedBox(height: 20),

                  // Quick Stats
                  _buildQuickStats(),
                  SizedBox(height: 20),

                  // Detailed Information
                  _buildDetailSection(
                      '🦠 สาเหตุของโรค', disease.cause, Colors.red[100]!),
                  _buildDetailSection(
                      '🔍 ลักษณะอาการ', disease.symptoms, Colors.orange[100]!),
                  _buildDetailSection(
                      '💊 วิธีการรักษา', disease.treatment, Colors.green[100]!),
                  _buildDetailSection(
                      '🛡️ การป้องกัน', disease.prevention, Colors.blue[100]!),
                  _buildDetailSection(
                      '📍 พื้นที่พบ', disease.found, Colors.purple[100]!),
                  _buildDetailSection('💰 ผลกระทบทางเศรษฐกิจ',
                      disease.economicImpact, Colors.amber[100]!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disease.name,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        disease.englishName,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: disease.severityColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    disease.severity,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('🌍', 'พื้นที่',
              '${disease.affectedAreas.length} ภาค', Colors.blue),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
              '📅', 'ฤดูกาล', disease.season.split(' - ')[0], Colors.green),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
              '⚠️', 'ความรุนแรง', disease.severity, disease.severityColor),
        ),
      ],
    );
  }

  Widget _buildStatCard(String icon, String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text(title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
      String title, String content, Color backgroundColor) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [backgroundColor, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
            SizedBox(height: 10),
            Text(
              content,
              style:
                  TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
