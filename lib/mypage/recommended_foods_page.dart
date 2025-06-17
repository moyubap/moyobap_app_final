import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecommendedFoodsPage extends StatefulWidget {
  const RecommendedFoodsPage({super.key});

  @override
  State<RecommendedFoodsPage> createState() => _RecommendedFoodsPageState();
}

class _RecommendedFoodsPageState extends State<RecommendedFoodsPage> {
  List<String> likedFoods = [];
  List<String> recommendedFoods = [];

  // ✅ 유사 음식 추천 매핑 (고도화된 AI 흉내)
  final Map<String, List<String>> foodSimilarityMap = {
    '김치찌개': ['된장찌개', '순두부찌개', '제육볶음', '감자탕'],
    '불고기': ['갈비', '제육볶음', '삼겹살', '육회'],
    '피자': ['햄버거', '파스타', '치킨', '스파게티'],
    '초밥': ['우동', '라멘', '텐동', '소바'],
    '샐러드': ['닭가슴살', '아보카도샐러드', '그릭요거트', '스무디'],
    '파스타': ['리조또', '피자', '라자냐', '까르보나라'],
    '짜장면': ['짬뽕', '탕수육', '볶음밥'],
    '비빔밥': ['돌솥비빔밥', '콩나물국밥', '육회비빔밥'],
    '햄버거': ['치킨버거', '감자튀김', '샌드위치'],
    '떡볶이': ['김밥', '순대', '튀김', '오뎅'],
    '돈까스': ['치즈돈까스', '가츠동', '카레라이스'],
    '라면': ['쫄면', '냉면', '비빔면'],
    '스테이크': ['토마호크', '바베큐폭립', '그릴치킨'],
    '아이스크림': ['젤라또', '팥빙수', '슈크림'],
    '탕수육': ['깐풍기', '깐쇼새우', '마파두부'],
    '우동': ['소바', '라멘', '덮밥'],
    '샌드위치': ['에그마요', '햄치즈샌드위치', '치킨샌드위치'],
    '오므라이스': ['가츠동', '규동', '카레오므라이스'],
    '리조또': ['파스타', '스프', '수프'],
    '부대찌개': ['순두부찌개', '청국장', '해장국'],
    '볶음밥': ['김치볶음밥', '마라볶음밥', '새우볶음밥'],
    '감자탕': ['뼈해장국', '묵은지찜', '우거지탕'],
    '샤브샤브': ['스키야키', '훠궈', '전골'],
    '찜닭': ['닭갈비', '닭도리탕', '불닭'],
    '쭈꾸미': ['낙지볶음', '오징어볶음', '문어숙회'],
    '냉면': ['비빔냉면', '물냉면', '쫄면'],
    '파인애플피자': ['고구마피자', '불고기피자', '콤비네이션피자'],
    '마카롱': ['티라미수', '푸딩', '컵케이크'],
    '김밥': ['참치김밥', '치즈김밥', '계란말이김밥'],
    '닭강정': ['양념치킨', '후라이드치킨', '간장치킨'],
    '양식샐러드': ['시저샐러드', '연어샐러드', '닭가슴살샐러드'],
    '스무디': ['바나나쉐이크', '딸기스무디', '망고스무디'],
    '연어덮밥': ['연어초밥', '연어스테이크', '연어샐러드'],
    '카레라이스': ['돈카츠카레', '야채카레', '해물카레'],
    '우삼겹덮밥': ['제육덮밥', '불고기덮밥', '치킨마요'],
    '닭도리탕': ['닭볶음탕', '닭갈비', '백숙'],
    '불닭볶음면': ['불닭볶음밥', '불족발', '불쭈꾸미'],
    '김치전': ['해물파전', '부추전', '감자전'],
    '돼지국밥': ['순대국밥', '내장탕', '설렁탕'],
    '잡채': ['잡채밥', '해물잡채', '버섯잡채'],
    '쌀국수': ['분짜', '반미', '월남쌈'],
    '초코케이크': ['딸기케이크', '치즈케이크', '당근케이크'],
    '파르페': ['요거트볼', '그래놀라', '그릭요거트'],
    '닭가슴살': ['닭가슴살스테이크', '닭가슴살샐러드', '닭가슴살샌드위치'],
    '카레': ['카레라이스', '돈카츠카레', '해물카레', '야채카레'],
    '회': ['연어회', '광어회', '우럭회', '회덮밥', '참치회', '연어초밥', '광어초밥'],
    '치킨': ['푸라닭','bbq','bhc','간장치킨','양념치킨'],
  };

  @override
  void initState() {
    super.initState();
    fetchUserLikesAndRecommend();
  }

  Future<void> fetchUserLikesAndRecommend() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = doc.data();
    likedFoods = List<String>.from(userData?['likes'] ?? []);
    if (likedFoods.isEmpty) return;

    final Set<String> result = {};

    for (final food in likedFoods) {
      result.addAll(foodSimilarityMap[food] ?? []);
    }

    result.removeWhere((f) => likedFoods.contains(f));

    setState(() {
      recommendedFoods = result.toList().take(50).toList(); // ✅ 최대 50개 추천
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 추천 음식')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: likedFoods.isEmpty
            ? const Center(
          child: Text('좋아하는 음식이 없습니다.\n프로필에서 먼저 설정해주세요.',
              textAlign: TextAlign.center),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('내가 좋아하는 음식', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: likedFoods.map((f) => Chip(label: Text(f))).toList(),
            ),
            const SizedBox(height: 24),
            const Text('AI 추천 음식', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            recommendedFoods.isEmpty
                ? const Text('추천할 음식이 없습니다.')
                : Wrap(
              spacing: 8,
              children: recommendedFoods.map((f) => Chip(label: Text(f))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
