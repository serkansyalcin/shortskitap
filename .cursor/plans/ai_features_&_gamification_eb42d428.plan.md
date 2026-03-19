---
name: AI Features & Gamification
overview: "Mevcut Laravel API + Flutter projesine 5 özellik ekleniyor: AI kapak üretimi (DALL-E 3), AI seslendirme (TTS-1), karakter/seri yönetimi, otomatik seslendirme (reader'da) ve rozet/gamification geliştirmeleri. Backend servisleri zaten var (OpenAIService, GeminiService), sadece doğru yerlere bağlanması ve Flutter tarafına yansıtılması gerekiyor."
todos:
  - id: migration-series-characters
    content: "Laravel: series, characters, paragraph audio_url, user_achievements seen_at migration dosyalarını oluştur ve çalıştır"
    status: completed
  - id: backend-ai-cover
    content: AiController::generateCover() metodunu yaz, DALL-E 3 → BunnyCDN → book güncelle, web route ekle
    status: completed
  - id: backend-ai-podcast
    content: GeneratePodcastFromTTSJob + AiController::generatePodcast() → TTS-1 → BunnyCDN → Podcast kaydı
    status: completed
  - id: backend-series-characters
    content: Series ve Character modelleri, Admin controller'ları ve CRUD'ları, AiController::generateCharacters() GPT entegrasyonu
    status: completed
  - id: backend-paragraph-audio
    content: ParagraphController::getAudio() endpoint, paragraf bazlı TTS üret/cache et
    status: completed
  - id: backend-gamification
    content: Yeni achievement condition type'ları, 8+ yeni rozet seed verisi, /achievements/{id}/seen endpoint
    status: completed
  - id: flutter-models-services
    content: SeriesModel, CharacterModel, AutoVoiceoverService, series_service.dart, character ilgili dart dosyaları
    status: completed
  - id: flutter-book-detail
    content: BookDetailScreen'e karakter kartları ve seri bandı ekle, BookModel'i güncelle
    status: completed
  - id: flutter-reader-voiceover
    content: ReaderScreen bottom bar'a ses toggle ekle, auto voiceover entegrasyonu
    status: completed
  - id: flutter-gamification-ui
    content: achievement_badge_grid.dart, achievement_celebration_widget.dart (Lottie), _ProfileTab güncelle
    status: completed
isProject: false
---

# AI Features & Gamification Plan

## Mevcut Altyapı (Değişmeyecek)

- `OpenAIService::generateImage()` → DALL-E 3 (1024×1024)
- `OpenAIService::generateAudio()` → TTS-1, voice: alloy
- `OpenAIService::generateBookDraft()` → GPT-4o-mini, `cover_prompt` field üretiyor
- BunnyCDN → `FILESYSTEM_DISK=bunny` ayarlı, dosya yükleme altyapısı mevcut
- `just_audio` → Flutter'da podcast oynatıcı çalışıyor
- Achievement + League sistemi → tam kurulu

---

## Feature 1 — AI Kapak Fotoğrafı Üretimi

### Backend (`kitaplig-api`)

`**[app/Http/Controllers/Admin/AiController.php](../kitaplig-api/app/Http/Controllers/Admin/AiController.php)**`

- Yeni method: `generateCover(Book $book)`
  - Book title + description'dan prompt oluştur
  - `OpenAIService::generateImage()` → DALL-E 3 URL döner
  - URL'den içeriği indir → BunnyCDN'e yükle (`Storage::disk('bunny')->put(...)`)
  - `$book->update(['cover_image_url' => $cdnUrl])`

`**[routes/web.php](../kitaplig-api/routes/web.php)**`

```php
POST /admin/ai/generate-cover/{book}
```

### Mobile — Değişiklik yok

Cover image zaten `cover_image_url` alanından CDN üzerinden gösteriliyor.

---

## Feature 2 — AI Seslendirme (Text-to-Speech)

### Backend

**Yeni Job: `app/Jobs/GeneratePodcastFromTTSJob.php`**

- `Queue::push()` ile asenkron çalışacak
- Book'un tüm paragraflarını çeker, max 4096 karakter bloklar halinde birleştirir
- `OpenAIService::generateAudio($text, $voice)` → MP3 binary
- BunnyCDN'e yükler → `Podcast` kaydı oluşturur (status: published)

`**[app/Http/Controllers/Admin/AiController.php](../kitaplig-api/app/Http/Controllers/Admin/AiController.php)**`

- Yeni method: `generatePodcast(Book $book)` → job dispatch eder, hemen 202 döner

**Route:**

```php
POST /admin/ai/generate-podcast/{book}
```

### Mobile — Değişiklik yok

Podcast player (`PodcastPlayerWidget`) zaten çalışıyor.

---

## Feature 3 — Karakter ve Seri Üretimi

### Backend — Migrations

`**database/migrations/2026_03_19_200001_create_series_table.php**`

```php
// series: id, title, slug, description, cover_image_url, author_id, is_published
```

`**database/migrations/2026_03_19_200002_add_series_to_books.php**`

```php
// books tablosuna: series_id (FK), series_order
```

`**database/migrations/2026_03_19_200003_create_characters_table.php**`

```php
// characters: id, book_id, name, description, role (protagonist/antagonist/supporting),
//             avatar_url, traits (JSON), is_ai_generated
```

### Backend — Models & Controllers

- `app/Models/Series.php` → `hasMany(Book::class)`
- `app/Models/Character.php` → `belongsTo(Book::class)`
- `app/Http/Controllers/Admin/SeriesController.php` → CRUD
- `app/Http/Controllers/Admin/CharacterController.php` → CRUD
- `AiController::generateCharacters(Book $book)` → GPT-4o-mini ile kitabın ilk 10 paragrafından karakter çıkarımı

### Backend — API Routes

`**[routes/api.php](../kitaplig-api/routes/api.php)**`

```php
GET  /series                         // Seri listesi
GET  /series/{id}                    // Seri detayı + books
GET  /books/{bookId}/characters      // Kitabın karakterleri
```

### Mobile — Yeni Dosyalar

- `lib/core/models/series_model.dart` → `SeriesModel`
- `lib/core/models/character_model.dart` → `CharacterModel`
- `lib/core/services/series_service.dart` → API çağrıları
- `lib/features/book/widgets/character_card_widget.dart` → Karakter kartı
- `lib/features/book/widgets/series_info_widget.dart` → Seri bilgisi

**Mevcut Güncelleme:**

- `lib/features/book/screens/book_detail_screen.dart` → Karakter listesi ve seri bandı eklenir
- `lib/core/models/book_model.dart` → `seriesId`, `seriesOrder`, `series?` alanları
- `lib/app/routes/app_router.dart` → `/series/:id` rotası

---

## Feature 4 — Otomatik Seslendirme (Dinleme / Reader'da)

### Backend — Yeni API Endpoint

`**[routes/api.php](../kitaplig-api/routes/api.php)`**

```php
GET /books/{bookId}/paragraphs/{paragraphId}/audio
```

`**app/Http/Controllers/Api/ParagraphController.php**` — `getAudio()` method:

- Paragraf için `audio_url` varsa direkt döndür
- Yoksa `OpenAIService::generateAudio()` ile üret → BunnyCDN'e yükle → `paragraph->update(['audio_url' => $url])`

`**database/migrations/2026_03_19_200004_add_audio_url_to_paragraphs.php**`

```php
// paragraphs tablosuna: audio_url (nullable)
```

### Mobile — Reader Screen Güncelleme

`**[lib/features/book/screens/reader_screen.dart](lib/features/book/screens/reader_screen.dart)**` (1205 satır, dikkatli düzenleme):

- `_ReaderBottomBar`'a ses ikonu toggle button ekle
- `AutoVoiceoverService` → `just_audio` `AudioPlayer` kullanır
- `PageView`'in `onPageChanged`'ında: autoVoice açıksa API'den audio URL çek → oynat
- Yükleme durumu için küçük dalga animasyonu (mevcut Lottie paketi)

**Yeni Dosya: `lib/core/services/auto_voiceover_service.dart`**

---

## Feature 5 — Gamification & Rozetler Geliştirmesi

### Backend

**Yeni achievement condition type'lar:**

- `series_completed`, `total_xp_earned`, `characters_discovered`

`**database/seeders/AchievementSeeder.php`** güncelleme:

- 8 yeni rozet (Seri Okuyucu, XP Ustası, Karakter Avcısı, vb.)

`**[routes/api.php](../kitaplig-api/routes/api.php)`**

```php
POST /achievements/{achievement}/seen  // Rozet kutlaması görüldü işaretle
```

`**database/migrations/2026_03_19_200005_add_seen_to_user_achievements.php**`

```php
// user_achievements pivot: seen_at (nullable timestamp)
```

### Mobile — Görsel İyileştirmeler

`**lib/core/models/achievement_model.dart**` → `rarity`, `xpReward`, `seenAt` alanları eklenir

**Yeni: `lib/features/profile/widgets/achievement_badge_grid.dart`**

- Kazanılan/kazanılmayan rozetleri grid'de gösterir
- Rozet nadirliğine göre renk (bronz/gümüş/altın/efsane)
- Kilitli rozetler bulanık + progress bar

**Yeni: `lib/features/profile/widgets/achievement_celebration_widget.dart`**

- Lottie konfeti animasyonu (mevcut Lottie paketi var)
- Rozet kazanıldığında reader/home ekranında overlay olarak gösterilir

**Home Screen güncellemesi:**

- `_ProfileTab` içinde rozet grid widget'ı entegre
- XP bar (mevcut `weekly_xp` verisinden)

---

## Uygulama Sırası

1. Migrations çalıştır (series, characters, paragraph audio_url, user_achievements seen_at)
2. Backend servisleri/controller'ları implement et
3. Flutter model/service katmanı
4. Flutter UI bileşenleri (karakter kartları, rozet grid, ses toggle)
5. Reader screen auto-voiceover entegrasyonu

