import 'package:kitaplig/core/models/interactive_element_model.dart';

import '../models/book.dart';

/// Örnek kitaplar - ileride API veya veritabanı ile değiştirilebilir
class SampleBooks {
  static List<Book> get all => [kucukPrens, sair];

  static const Book kucukPrens = Book(
    id: '1',
    title: 'Küçük Prens',
    author: 'Antoine de Saint-Exupéry',
    genre: 'Masal',
    description:
        'Küçük Prens, bir çocuğun gözüyle büyüklerin dünyasını anlatan zamansız bir eser.',
    paragraphs: [
      'Büyükler sayılara bayılır. Onlara yeni bir arkadaşınızdan söz ettiğinizde asla önemli şeyleri sormazlar.',
      '“Sesi nasıldı? Hangi oyunları seviyor? Kelebek koleksiyonu var mı?” diye sormazlar.',
      '“Kaç yaşında? Kaç kardeşi var? Babası kaç kilo?” diye sorarlar.',
      'Ve siz de “Güzel bir evi var, tuğladan, üç pencereli” derseniz, evi bir türlü gözlerinin önüne getiremezler.',
      '“Kırmızı tuğlalı, sümbül çiçeklerinin olduğu bir ev” demeniz gerekir. O zaman “Ah, ne güzel!” derler.',
      'Ben altı yaşındayken bir keresinde “Yutan Yılanlar” adlı doğa tarihi kitabında muhteşem bir resim görmüştüm.',
      'Resimde bir boa yılanı bir hayvanı yutuyordu. İşte o resmin kopyası.',
      'Kitapta şöyle yazıyordu: “Boa yılanı avını çiğnemeden yutar, sonra kıpırdamadan altı ay uyur; ta ki sindirene kadar.”',
      'O zaman ormanın tehlikeleri üzerine çok düşündüm ve bir kurşunkalemle ilk resmimi çizdim.',
      'İşte benim 1 numaralı resmim. Bir boa yılanının bir fili yuttuğunu gösteriyordu.',
    ],
    interactiveElements: [
      InteractiveElementModel(
        id: 1,
        type: 'quiz',
        payload: {
          'questions': [
            {
              'question': 'Küçük Prens kitabında büyükler neye bayılır?',
              'options': ['Sayılara', 'Kelebeklere', 'Şarkılara', 'Resimlere'],
              'correct_answer': 'Sayılara',
            },
            {
              'question': 'Boa yılanı avını ne yapmadan yutar?',
              'options': ['Çiğnemeden', 'Koşmadan', 'Uyumadan', 'Çizmeden'],
              'correct_answer': 'Çiğnemeden',
            },
          ],
        },
        rewardPoints: 10,
      ),
      InteractiveElementModel(
        id: 2,
        type: 'match',
        payload: {
          'instruction': 'Kelimeleri doğru eşleştir.',
          'pairs': [
            {'left': 'Yutan', 'right': 'Yılan'},
            {'left': 'Kırmızı', 'right': 'Tuğla'},
            {'left': 'Sümbül', 'right': 'Çiçek'},
          ],
        },
        rewardPoints: 10,
      ),
    ],
  );

  static const Book sair = Book(
    id: '2',
    title: 'Sır',
    author: 'Örnek Yazar',
    genre: 'Şiir',
    description: 'Kısa düşünceler ve şiirsel metinler.',
    paragraphs: [
      'Her sabah aynı sokaklardan geçiyorum. Aynı ağaçlar, aynı taşlar.',
      'Ama bugün bir yaprak düştü önüme. Sarı, kırışık. Belki sonbaharın ilk habercisi.',
      'İnsan bazen bir cümleyle değişir. Bazen bir bakışla. Bazen sadece sessizlikle.',
      'Kitaplar sessiz arkadaşlardır. Ne soru sorarlar ne de seni yargılarlar.',
      'Sadece açarsın ve dünyalarına girersin.',
    ],
  );
}
