import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// UI strings driven by [locale] from [appLocaleProvider], not [Localizations.localeOf]
/// (MaterialApp stays on English for delegate stability).
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  bool get isEnglish => locale.languageCode == 'en';
  bool get isArabic => locale.languageCode == 'ar';
  bool get isKurmanji => locale.languageCode == 'kmr';
  bool get isSorani => locale.languageCode == 'ckb' || (!isEnglish && !isKurmanji && !isArabic);

  String get loginTitle {
    if (isArabic) return 'أهلاً وسهلاً';
    if (isKurmanji) return 'Bi xêr hatî';
    if (isSorani) return 'بەخێربێیت';
    return 'Welcome';
  }

  String get loginSubtitle {
    if (isArabic) return 'أدخل رمز الوصول للمتابعة';
    if (isKurmanji) return 'Ji kerema xwe koda xwe binivîse da ku berdewam bikî';
    if (isSorani) return 'تکایە کۆدی چوونەژوورەوە بنووسە بۆ بەردەوامبوون';
    return 'Enter your access code to continue';
  }

  String get loginHint => '☆☆☆☆☆☆';

  String get loginButton {
    if (isArabic) return 'متابعة';
    if (isKurmanji) return 'Berdewam bike';
    if (isSorani) return 'بەردەوامبە';
    return 'Continue';
  }

  String get loginErrorEmpty {
    if (isArabic) return 'أدخل الرمز';
    if (isKurmanji) return 'Kodê binivîse';
    if (isSorani) return 'کۆدەکە بنووسە';
    return 'Enter a code';
  }

  String get loginErrorInvalid {
    if (isArabic) return 'الرمز غير صحيح';
    if (isKurmanji) return 'Kod nehat nasîn';
    if (isSorani) return 'کۆدەکە هەڵەیە';
    return 'Code not recognized';
  }

  String get loginErrorNetwork {
    if (isArabic) return 'تحقق من الاتصال وحاول مرة أخرى';
    if (isKurmanji) return 'Têkiliya înternetê kontrol bike û dîsa biceribîne';
    if (isSorani) return 'پەیوەندی ئینتەرنێت بپشکنە و دووبارە هەوڵبدەوە';
    return 'Check connection and try again';
  }

  String get appBrand => 'KOBANI 4K';

  String get appTagline {
    if (isArabic) return 'ترفيه مميز';
    if (isKurmanji) return 'Cîhanek ji kêf û wext derbaskirinê';
    if (isSorani) return 'جیهانێک لە کاتبەسەربردن';
    return 'Premium entertainment';
  }

  String get noChannels {
    if (isArabic) return 'لا توجد قنوات بعد';
    if (isKurmanji) return 'Hêj qenal nînin';
    if (isSorani) return 'هیچ کەناڵێک بەردەست نییە';
    return 'No channels yet';
  }

  String get noChannelsHint {
    if (isArabic) return 'ستظهر القنوات عند مزامنة قائمتك.';
    if (isKurmanji) return 'Gava lîsteya te tê hevdeng kirin ew ê xuya bibin.';
    if (isSorani) return 'کەناڵەکان دەردەکەون کاتێک لیستەکەت هاوکات دەکرێت.';
    return 'They appear when your library syncs.';
  }

  String get nowPlaying {
    if (isArabic) return 'مميّز';
    if (isKurmanji) return 'Pêşniyarkirî';
    if (isSorani) return 'جێی سەرنج';
    return 'Featured';
  }

  String get featuredNewHint {
    if (isArabic) return 'قناة جديدة متاحة في قائمتك. اضغط شاهد للبدء.';
    if (isKurmanji) return 'Qenalek nû li lîsteya te hat zêdekirin. Dest bide "Temaşe bike".';
    if (isSorani) return 'کەناڵێکی نوێ بۆ لیستەکەت زیادکراوە، دەست لە «ببینە» بدە بۆ سەیرکردن.';
    return 'A new channel is available in your lineup. Tap Watch to start playing.';
  }

  String get watchNow {
    if (isArabic) return 'شاهد';
    if (isKurmanji) return 'Temaşe bike';
    if (isSorani) return 'ببینە';
    return 'Watch';
  }

  String get channelLoadError {
    if (isArabic) return 'تعذّر تحميل القنوات';
    if (isKurmanji) return 'Qenal nehatin xwendin';
    if (isSorani) return 'نەتوانرا کەناڵەکان بخوێنرێتەوە';
    return 'Could not load channels';
  }

  String get settingsTooltip {
    if (isArabic) return 'الإعدادات';
    if (isKurmanji) return 'Sazkirin';
    if (isSorani) return 'ڕێکخستنەکان';
    return 'Settings';
  }

  String get settingsTitle {
    if (isArabic) return 'الإعدادات';
    if (isKurmanji) return 'Sazkirin';
    if (isSorani) return 'ڕێکخستنەکان';
    return 'Settings';
  }

  String get sectionPlayback {
    if (isArabic) return 'التشغيل';
    if (isKurmanji) return 'Lêdan';
    if (isSorani) return 'پەخشکردن';
    return 'Playback';
  }

  String get sectionVideo {
    if (isArabic) return 'حجم الفيديو';
    if (isKurmanji) return 'Mezinahiya Vîdyoyê';
    if (isSorani) return 'قەبارەی ڤیدیۆ';
    return 'Video fit';
  }

  String get sectionInterface {
    if (isArabic) return 'الواجهة';
    if (isKurmanji) return 'Rûkar';
    if (isSorani) return 'ڕووکار';
    return 'Interface';
  }

  String get sectionGradientTheme {
    if (isArabic) return 'المظهر والخلفية';
    if (isKurmanji) return 'Reng û Paşxane';
    if (isSorani) return 'شێوازی ڕەنگ و پاشبنە';
    return 'Theme & backdrop';
  }

  String get gradientThemeCaption {
    if (isArabic) return 'مظهر التدرج للوحة التحكم وهذه الشاشة';
    if (isKurmanji) return 'Rengên ji bo dashboard û vê rûpelê';
    if (isSorani) return 'شێوازی ڕەنگیزە بۆ داشبۆرد و ئەم شاشەیە';
    return 'Gradient look for dashboard and this screen';
  }

  String get gradientClassic {
    if (isArabic) return 'منتصف الليل';
    if (isKurmanji) return 'Nîvê Şevê';
    if (isSorani) return 'نیوەشەو';
    return 'Midnight';
  }

  String get gradientOcean {
    if (isArabic) return 'أعماق المحيط';
    if (isKurmanji) return 'Kûrahiya Okyanûsê';
    if (isSorani) return 'قووڵایی ئۆقیانوس';
    return 'Ocean abyss';
  }

  String get gradientGold {
    if (isArabic) return 'غروب ذهبي';
    if (isKurmanji) return 'Zêrîn';
    if (isSorani) return 'ئاسۆیی زێڕین';
    return 'Gold sunset';
  }

  String get gradientViolet {
    if (isArabic) return 'ضباب بنفسجي';
    if (isKurmanji) return 'Mijê Mor';
    if (isSorani) return 'تەمومژی مۆر';
    return 'Violet haze';
  }

  String get gradientEmber {
    if (isArabic) return 'توهج جمري (افتراضي)';
    if (isKurmanji) return 'Gêla Pêtê (Bingehan)';
    if (isSorani) return 'گەشیی پۆلێتی (بنەڕەتی)';
    return 'Ember glow (default)';
  }

  String get sectionLanguage {
    if (isArabic) return 'اللغة';
    if (isKurmanji) return 'Ziman';
    if (isSorani) return 'زمانەکان';
    return 'Language';
  }

  String get sectionAccount {
    if (isArabic) return 'الحساب';
    if (isKurmanji) return 'Hesab';
    if (isSorani) return 'هەژمار';
    return 'Account';
  }

  String get sectionAbout {
    if (isArabic) return 'حول';
    if (isKurmanji) return 'Derbar';
    if (isSorani) return 'دەربارە';
    return 'About';
  }

  String get keepScreenOnTitle {
    if (isArabic) return 'إبقاء الشاشة مضاءة';
    if (isKurmanji) return 'Dîmender ronî bihêle';
    if (isSorani) return 'داگیرساندنی شاشە';
    return 'Keep screen on';
  }

  String get keepScreenOnSub {
    if (isArabic) return 'أثناء تشغيل الفيديو';
    if (isKurmanji) return 'Dema vîdyo tê lêdan';
    if (isSorani) return 'ڕێگری لە کوژانەوەی شاشە لەکاتی پەخشکردندا';
    return 'While video is playing';
  }

  String get autoHideTitle {
    if (isArabic) return 'إخفاء أزرار التحكم';
    if (isKurmanji) return 'Bikojkan veşêre';
    if (isSorani) return 'شاردنەوەی دوگمەکان';
    return 'Hide controls';
  }

  String get autoHideSub {
    if (isArabic) return 'إخفاء شريط المشغّل، اضغط لإظهاره';
    if (isKurmanji) return 'Bi dest lêdanê dubare nîşan bide';
    if (isSorani) return 'شاردنەوەی شریتی پلەیەر، دەست لێ بدە بۆ پیشاندانەوە';
    return 'Fade player bars; tap to show';
  }

  String get clockTitle {
    if (isArabic) return 'الساعة في المشغّل';
    if (isKurmanji) return 'Demjimêr di lîstikvanê de';
    if (isSorani) return 'کاتژمێر لە پلەیەر';
    return 'Clock in player';
  }

  String serverName(int number) {
    if (isArabic) return 'خادم $number';
    if (isKurmanji) return 'PÊŞKÊŞKER $number';
    if (isSorani) return 'سێرڤەری $number';
    return 'SERVER $number';
  }

  String get clockSub {
    if (isArabic) return 'عرض الوقت في الشريط العلوي';
    if (isKurmanji) return 'Dema lîstikvan nîşan bide';
    if (isSorani) return 'پیشاندانی کات لە شریتی سەرەوە';
    return 'Time in top bar';
  }

  String get videoFitCaption {
    if (isArabic) return 'كيفية ملء الفيديو للشاشة';
    if (isKurmanji) return 'Çawa vîdyo li ser ekranê rûne';
    if (isSorani) return 'چۆنیەتی گونجاندنی ڤیدیۆ لەسەر شاشە';
    return 'How video fills the screen';
  }

  String get reduceMotionTitle {
    if (isArabic) return 'تقليل الحركة';
    if (isKurmanji) return 'Tevgeran kêm bike';
    if (isSorani) return 'کەمکردنەوەی جوڵە';
    return 'Reduce motion';
  }

  String get reduceMotionSub {
    if (isArabic) return 'رسوم متحركة أقصر';
    if (isKurmanji) return 'Anîmasyonên kurtir';
    if (isSorani) return 'بەکارهێنانی جوڵەی کورتتر';
    return 'Shorter animations';
  }

  String get logoutTitle {
    if (isArabic) return 'تسجيل الخروج';
    if (isKurmanji) return 'Derkeve';
    if (isSorani) return 'چوونەدەرەوە';
    return 'Sign out';
  }

  String get logoutSub {
    if (isArabic) return 'حذف الحساب من هذا الجهاز';
    if (isKurmanji) return 'Hesabê xwe ji vî cîhazî rakin';
    if (isSorani) return 'سڕینەوەی هەژمار لەسەر ئەم ئامێرە';
    return 'Clear login on this device';
  }

  String get logoutButton {
    if (isArabic) return 'تسجيل الخروج';
    if (isKurmanji) return 'Derkeve';
    if (isSorani) return 'چوونەدەرەوە';
    return 'Sign out';
  }

  String get aboutTitle => 'KOBANI 4K';

  String get aboutSub {
    if (isArabic) return 'الإصدار 1.2.0 · IPTV';
    if (isKurmanji) return 'Guherto 1.2.0 · IPTV';
    if (isSorani) return 'وەشانی ١.٢.٠ · IPTV';
    return 'Version 1.2.0 · IPTV';
  }

  String get langEnglish => 'English';
  String get langKurdishSorani => 'کوردی (سۆرانی)';
  String get langKurdishKurmanji => 'Kurdî (Kurmancî)';
  String get langArabic => 'العربية';

  String get cancel {
    if (isArabic) return 'إلغاء';
    if (isKurmanji) return 'Betal bike';
    if (isSorani) return 'هەڵوەشاندنەوە';
    return 'Cancel';
  }

  String get password {
    if (isArabic) return 'كلمة المرور';
    if (isKurmanji) return 'Şîfre';
    if (isSorani) return 'وشەی نهێنی';
    return 'Password';
  }

  String get enter {
    if (isArabic) return 'دخول';
    if (isKurmanji) return 'Têkeve';
    if (isSorani) return 'چوونەژوورەوە';
    return 'Enter';
  }

  String get fullscreenTooltip {
    if (isArabic) return 'ملء الشاشة';
    if (isKurmanji) return 'Ekrana tije';
    if (isSorani) return 'پڕ بە شاشە';
    return 'Fullscreen';
  }

  String get navHome {
    if (isArabic) return 'الرئيسية';
    if (isKurmanji) return 'Mal';
    if (isSorani) return 'سەرەکی';
    return 'Home';
  }

  String get navLiveTv {
    if (isArabic) return 'تلفزيون مباشر';
    if (isKurmanji) return 'Zindî TV';
    if (isSorani) return 'ڕاستەوخۆ';
    return 'Live TV';
  }

  String get navMovies {
    if (isArabic) return 'الأفلام';
    if (isKurmanji) return 'Fîlm';
    if (isSorani) return 'فیلمەکان';
    return 'Movies';
  }

  String get navSport {
    if (isArabic) return 'الرياضة';
    if (isKurmanji) return 'Spor';
    if (isSorani) return 'وەرزش';
    return 'Sport';
  }

  String get navWorldCup {
    if (isArabic) return 'كأس العالم 26';
    if (isKurmanji) return 'Kûpaya Cîhanê 26';
    if (isSorani) return 'مۆندیالی ٢٠٢٦';
    return 'World Cup 26';
  }

  String get navProfile {
    if (isArabic) return 'الإعدادات';
    if (isKurmanji) return 'Sazkirin';
    if (isSorani) return 'ڕێکخستنەکان';
    return 'Settings';
  }

  String get navFavorites {
    if (isArabic) return 'المفضلة';
    if (isKurmanji) return 'Bijare';
    if (isSorani) return 'دڵخوازەکانم';
    return 'Favorites';
  }

  String get navRecent {
    if (isArabic) return 'الأخيرة';
    if (isKurmanji) return 'Dîtî';
    if (isSorani) return 'بینراوەکانی دوایی';
    return 'Recent';
  }

  String get searchHint {
    if (isArabic) return 'البحث عن قنوات...';
    if (isKurmanji) return 'Lêgerîn li qenalan...';
    if (isSorani) return 'گەڕان بەدوای کەناڵ...';
    return 'Search channels…';
  }

  String get categoriesTitle {
    if (isArabic) return 'الفئات';
    if (isKurmanji) return 'Kategorî';
    if (isSorani) return 'هاوپۆلەکان';
    return 'Categories';
  }

  String get channelListTitle {
    if (isArabic) return 'قائمة القنوات';
    if (isKurmanji) return 'Lîsteya Qenalan';
    if (isSorani) return 'لیستی کەناڵەکان';
    return 'Channel list';
  }

  String get noChannelsInSection {
    if (isArabic) return 'لا توجد قنوات في هذا القسم';
    if (isKurmanji) return 'Qenal li vê beşê nînin';
    if (isSorani) return 'هیچ کەناڵێک لەم بەشەدا نییە';
    return 'No channels in this section';
  }

  String get noFavorites {
    if (isArabic) return 'لا توجد مفضلات بعد';
    if (isKurmanji) return 'Hêj bijare nînin';
    if (isSorani) return 'هیچ دڵخوازێک نییە';
    return 'No favorites yet';
  }

  String get noFavoritesHint {
    if (isArabic) return 'اضغط مطولاً على قناة أو انقر على النجمة في المشغّل لإضافتها.';
    if (isKurmanji) return 'Ji bo zêdekirinê, pêl stêrkê bike.';
    if (isSorani) return 'ئەستێرەی سەر پلەیەرەکە دابگرە بۆ زیادکردنی کەناڵ.';
    return 'Long-press a channel on the home grid or tap the star in the player.';
  }

  String get noRecent {
    if (isArabic) return 'لم يتم تشغيل شيء بعد';
    if (isKurmanji) return 'Hêj tiştek nehatiye lîstin';
    if (isSorani) return 'هیچ شتێک نەبینراوە';
    return 'Nothing played yet';
  }

  String get noRecentHint {
    if (isArabic) return 'القنوات التي تفتحها تظهر هنا للعودة السريعة.';
    if (isKurmanji) return 'Qenalên te li vir xuya dibin.';
    if (isSorani) return 'کەناڵەکان لێرەدا دەردەکەون بۆ بینینەوەی خێرا.';
    return 'Channels you open appear here for quick return.';
  }

  String get sectionLibrary {
    if (isArabic) return 'المكتبة';
    if (isKurmanji) return 'Pirtûkxane';
    if (isSorani) return 'کتێبخانە';
    return 'Library';
  }

  String get clearFavoritesTitle {
    if (isArabic) return 'مسح المفضلة';
    if (isKurmanji) return 'Bijareyan Paqij bike';
    if (isSorani) return 'سڕینەوەی دڵخوازەکان';
    return 'Clear favorites';
  }

  String get clearFavoritesSub {
    if (isArabic) return 'إزالة جميع القنوات المفضلة';
    if (isKurmanji) return 'Hemû qenalên bijare jê bibe';
    if (isSorani) return 'سڕینەوەی هەموو کەناڵە دڵخوازەکان';
    return 'Remove all starred channels on this device';
  }

  String get clearRecentTitle {
    if (isArabic) return 'مسح سجل المشاهدة';
    if (isKurmanji) return 'Dîrokê Paqij bike';
    if (isSorani) return 'سڕینەوەی مێژووی بینین';
    return 'Clear watch history';
  }

  String get clearRecentSub {
    if (isArabic) return 'حذف جميع القنوات المشاهدة مؤخراً';
    if (isKurmanji) return 'Hemû qenalên dîtî jê bibe';
    if (isSorani) return 'سڕینەوەی هەموو کەناڵە بینراوەکان';
    return 'Forget recently opened channels on this device';
  }

  String get clearLibraryConfirmBody {
    if (isArabic) return 'لا يمكن التراجع عن هذا.';
    if (isKurmanji) return 'Ev nayê betalkirin.';
    if (isSorani) return 'ئەم پڕۆسەیە ناگەڕێتەوە دواوە.';
    return 'This cannot be undone.';
  }

  String get clearButton {
    if (isArabic) return 'مسح';
    if (isKurmanji) return 'Paqij bike';
    if (isSorani) return 'سڕینەوە';
    return 'Clear';
  }

  String get favoriteChannel {
    if (isArabic) return 'إضافة إلى المفضلة';
    if (isKurmanji) return 'Zêdeyî bijareyan bike';
    if (isSorani) return 'زیادکردن بۆ دڵخوازەکان';
    return 'Add to favorites';
  }

  String get unfavoriteChannel {
    if (isArabic) return 'إزالة من المفضلة';
    if (isKurmanji) return 'Ji bijareyan derxîne';
    if (isSorani) return 'سڕینەوە لە دڵخوازەکان';
    return 'Remove from favorites';
  }

  String fitLabel(BoxFit fit) {
    if (isArabic) {
      return switch (fit) {
        BoxFit.contain => 'احتواء (بدون قص)',
        BoxFit.cover => 'تغطية (قص الأطراف)',
        BoxFit.fill => 'ملء الشاشة',
        BoxFit.fitWidth => 'مطابقة العرض',
        BoxFit.fitHeight => 'مطابقة الارتفاع',
        BoxFit.scaleDown => 'تصغير',
        BoxFit.none => 'الحجم الأصلي',
      };
    }
    if (isKurmanji) {
      return switch (fit) {
        BoxFit.contain => 'Tijî (Bê birîn)',
        BoxFit.cover => 'Rûpoş (Derdor birîn)',
        BoxFit.fill => 'Tije bike',
        BoxFit.fitWidth => 'Bi firehiyê re hevaheng bike',
        BoxFit.fitHeight => 'Bi bilindiyê re hevaheng bike',
        BoxFit.scaleDown => 'Biçûk bike',
        BoxFit.none => 'Mezinahiya rastîn',
      };
    }
    if (isSorani) {
      return switch (fit) {
        BoxFit.contain => 'تەواو (بە بێ بڕین)',
        BoxFit.cover => 'داپۆشین (بڕینی دەورووبەر)',
        BoxFit.fill => 'پڕکردنەوەی شاشە',
        BoxFit.fitWidth => 'گونجاندن لەگەڵ پانی',
        BoxFit.fitHeight => 'گونجاندن لەگەڵ بەرزی',
        BoxFit.scaleDown => 'پچوکردنەوە',
        BoxFit.none => 'قەبارەی ئەسڵی',
      };
    }
    return AppSettingsData.labelForFit(fit);
  }
  String get sectionStorage {
    if (isArabic) return 'التخزين والذاكرة المؤقتة';
    if (isKurmanji) return 'Bîrge û Kaş';
    if (isSorani) return 'بیرگە و کاش';
    return 'Storage & Cache';
  }

  String get storagePosters {
    if (isArabic) return 'ملصقات الأفلام والمسلسلات';
    if (isKurmanji) return 'Posterên Fîlm û Rêzefîlman';
    if (isSorani) return 'پۆستەری فیلم و زنجیرەکان';
    return 'Movie & Series Posters';
  }

  String get storageEpg {
    if (isArabic) return 'بيانات دليل التلفزيون EPG';
    if (isKurmanji) return 'Daneyên Rêberê TV EPG';
    if (isSorani) return 'داتای ڕێبەری تەلەفزیۆنی EPG';
    return 'EPG TV Guide Data';
  }

  String get storageLogs {
    if (isArabic) return 'السجلات والبيانات المؤقتة';
    if (isKurmanji) return 'Daneyên Demkî û Log';
    if (isSorani) return 'داتای کاتی و لۆگەکان';
    return 'Temporary Logs & Data';
  }

  String get calculating {
    if (isArabic) return 'جاري الحساب...';
    if (isKurmanji) return 'Tê hesibandin...';
    if (isSorani) return 'لە هەژمارکردندایە...';
    return 'Calculating...';
  }

  String get sectionSubtitles {
    if (isArabic) return 'تفضيلات الترجمة (VOD)';
    if (isKurmanji) return 'Vebijarkên Binnivîsê (VOD)';
    if (isSorani) return 'هەڵبژاردەکانی ژێرنووس (VOD)';
    return 'Subtitle Preferences (VOD)';
  }

  String get subtitleCaption {
    if (isArabic) return 'تخصيص مظهر الترجمة في الأفلام والمسلسلات';
    if (isKurmanji) return 'Xuyabûna binnivîsan di fîlm û rêzefîlman de sererast bike';
    if (isSorani) return 'شێوازی دەرکەوتنی ژێرنووس لە فیلم و زنجیرەکاندا ڕێکبخە';
    return 'Customize how subtitles look in movies and series';
  }

  String get subtitleFontSize {
    if (isArabic) return 'حجم الخط';
    if (isKurmanji) return 'Mezinahiya Fontê';
    if (isSorani) return 'قەبارەی فۆنت';
    return 'Font Size';
  }

  String get subtitleColor {
    if (isArabic) return 'لون النص';
    if (isKurmanji) return 'Rengê Nivîsê';
    if (isSorani) return 'ڕەنگی دەق';
    return 'Text Color';
  }

  String get subtitleBgOpacity {
    if (isArabic) return 'شفافية الخلفية';
    if (isKurmanji) return 'Tîrêjiya Paşxanê';
    if (isSorani) return 'ڕوونی پاشبنە';
    return 'Background Opacity';
  }

  String get subtitleBgOff {
    if (isArabic) return 'مغلق';
    if (isKurmanji) return 'Girtî';
    if (isSorani) return 'کوژاوە';
    return 'Off';
  }

  String get subtitleBgSemi {
    return '45%';
  }

  String get subtitleBgSolid {
    if (isArabic) return 'مصمت';
    if (isKurmanji) return 'Tîr';
    if (isSorani) return 'تۆخ';
    return 'Solid';
  }

  String get subtitleSample {
    if (isArabic) return 'نص ترجمة تجريبي';
    if (isKurmanji) return 'Mînaka Nivîsa Binnivîsê';
    if (isSorani) return 'نموونەی دەقی ژێرنووس';
    return 'Sample Subtitle Text';
  }

  String get sectionPlaybackNetwork {
    if (isArabic) return 'التشغيل والشبكة';
    if (isKurmanji) return 'Lêdan û Înternet';
    if (isSorani) return 'پەخشکردن و ئینتەرنێت';
    return 'Playback & Network';
  }

  String get hardwareAccel {
    if (isArabic) return 'تسريع العتاد';
    if (isKurmanji) return 'Lezkirina Hardware';
    if (isSorani) return 'خێراکردنی ڕەقەکاڵا';
    return 'Hardware Acceleration';
  }

  String get hardwareAccelSub {
    if (isArabic) return 'استخدام فك تشفير العتاد (أوقفه لإصلاح التقطع على الأجهزة القديمة)';
    if (isKurmanji) return 'Dekodkirina hardware bi kar bîne (ji bo çareserkirina sekinînê di cîhazên kevn de bigire)';
    if (isSorani) return 'بەکارهێنانی دیـکۆدینگی ڕەقەکاڵا (بیکوژێنەوە بۆ چارەسەری وەستان لە ئامێرە کۆنەکاندا)';
    return 'Use hardware decoding (turn off to fix stuttering on older devices)';
  }

  String get dataSaver {
    if (isArabic) return 'وضع توفير البيانات';
    if (isKurmanji) return 'Moda Parastina Daneyê';
    if (isSorani) return 'مۆدی پاشەکەوتکردنی داتا';
    return 'Data Saver Mode';
  }

  String get dataSaverSub {
    if (isArabic) return 'طلب جودة أقل تلقائياً على شبكات الهاتف';
    if (isKurmanji) return 'Bi awayekî otomatîk daxwaza weşanên qalîteya nizm li ser torên mobîl dike';
    if (isSorani) return 'بەشێوەیەکی ئۆتۆماتیکی داوای کوالێتی نزمتر دەکات لەسەر تۆڕەکانی مۆبایل';
    return 'Automatically request lower quality streams on mobile networks';
  }

  String get sectionDiagnostics {
    if (isArabic) return 'تشخيص الجهاز والشبكة';
    if (isKurmanji) return 'Kontrola Cîhaz û Torê';
    if (isSorani) return 'پشکنینی ئامێر و ئینتەرنێت';
    return 'Device & Network Diagnostics';
  }

  String get displayOutput {
    if (isArabic) return 'مخرج الشاشة';
    if (isKurmanji) return 'Derketina Dîmenderê';
    if (isSorani) return 'دەرچەی شاشە';
    return 'Display Output';
  }

  String get display4k {
    if (isArabic) return 'يدعم 4K Ultra HD';
    if (isKurmanji) return 'Piştgiriya 4K Ultra HD dike';
    if (isSorani) return 'پشتگیری 4K Ultra HD دەکات';
    return '4K Ultra HD Capable';
  }

  String get display1080p {
    return '1080p Full HD';
  }

  String get display720p {
    return '720p HD Ready';
  }

  String get speedTest {
    if (isArabic) return 'اختبار سرعة الإنترنت';
    if (isKurmanji) return 'Testa Leza Înternetê';
    if (isSorani) return 'پشکنینی خێرایی ئینتەرنێت';
    return 'Internet Speed Test';
  }

  String get speedTestSub {
    if (isArabic) return 'اختبر سرعة اتصالك للبث بجودة 4K/HD';
    if (isKurmanji) return 'Leza girêdana xwe ji bo weşana 4K/HD biceribîne';
    if (isSorani) return 'خێرایی ئینتەرنێتەکەت بپشکنە بۆ پەخشی 4K/HD';
    return 'Test your connection speed for 4K/HD streaming';
  }

  String speedTestResult(String speed) {
    if (isArabic) return 'آخر نتيجة: $speed ميجابت';
    if (isKurmanji) return 'Encama dawî: $speed Mbps';
    if (isSorani) return 'کۆتا ئەنجام: $speed مێگابایت';
    return 'Last result: $speed Mbps';
  }

  String get runTest {
    if (isArabic) return 'ابدأ الاختبار';
    if (isKurmanji) return 'TEST BIKIN';
    if (isSorani) return 'پشکنین بکە';
    return 'RUN TEST';
  }

  String get sectionSupport {
    if (isArabic) return 'الدعم والتحديثات';
    if (isKurmanji) return 'Piştgirî û Nûvekirin';
    if (isSorani) return 'پشتگیری و نوێکردنەوەکان';
    return 'Support & Updates';
  }

  String get checkUpdates {
    if (isArabic) return 'التحقق من التحديثات';
    if (isKurmanji) return 'Kontrola Nûvekirinê';
    if (isSorani) return 'پشکنین بۆ نوێکردنەوە';
    return 'Check for Updates';
  }

  String get checkUpdatesSub {
    if (isArabic) return 'تأكد من حصولك على أحدث الميزات';
    if (isKurmanji) return 'Piştrast be ku taybetmendiyên herî nû li cem te ne';
    if (isSorani) return 'دڵنیابە لەوەی نوێترین تایبەتمەندییەکانت هەیە';
    return 'Ensure you have the latest features';
  }

  String get joinTelegram {
    if (isArabic) return 'انضم لتليجرامنا';
    if (isKurmanji) return 'Tevlî Telegrama me bibe';
    if (isSorani) return 'بەشداربە لە تێلیگرامەکەمان';
    return 'Join our Telegram';
  }

  String get joinTelegramSub {
    if (isArabic) return 'احصل على الدعم وآخر الأخبار';
    if (isKurmanji) return 'Piştgirî û nûçeyên herî nû bistîne';
    if (isSorani) return 'پشتگیری و نوێترین هەواڵەکان وەربگرە';
    return 'Get support and latest news';
  }

  String get whatsNew {
    if (isArabic) return 'ما الجديد؟';
    if (isKurmanji) return 'Çi Nû ye?';
    if (isSorani) return 'چی نوێیە؟';
    return 'What\'s New?';
  }

  String get whatsNewKurdish {
    if (isArabic) return 'مترجم كردي';
    if (isKurmanji) return 'Wergerê Kurdî';
    if (isSorani) return 'وەرگێڕی کوردی';
    return 'Kurdish Translator';
  }

  String get whatsNewKurdishSub {
    if (isArabic) return 'تمت إضافة دعم كامل للكردية الكرمانجية';
    if (isKurmanji) return 'Piştgiriya tam a Kurdiya Kurmancî hat zêdekirin';
    if (isSorani) return 'پشتگیری تەواوی کوردی کرمانجی زیادکرا';
    return 'Added full Kurdish Kurmanji support';
  }

  String get whatsNewDataSaver {
    if (isArabic) return 'توفير البيانات';
    if (isKurmanji) return 'Parastina Daneyê';
    if (isSorani) return 'پاشەکەوتکردنی داتا';
    return 'Data Saver';
  }

  String get whatsNewDataSaverSub {
    if (isArabic) return 'توفير الإنترنت على شبكات الهاتف';
    if (isKurmanji) return 'Parastina înternetê li ser torên mobîl';
    if (isSorani) return 'پاشەکەوتکردنی ئینتەرنێت لەسەر تۆڕەکانی مۆبایل';
    return 'Save bandwidth on mobile networks';
  }

  String get whatsNewStorage {
    if (isArabic) return 'مدير التخزين';
    if (isKurmanji) return 'Rêveberê Bîrgeyê';
    if (isSorani) return 'بەڕێوەبەری بیرگە';
    return 'Storage Manager';
  }

  String get whatsNewStorageSub {
    if (isArabic) return 'مسح الذاكرة المؤقتة والملصقات بسهولة';
    if (isKurmanji) return 'Paqijkirina kaş û posteran bi hêsanî';
    if (isSorani) return 'سڕینەوەی کاش و پۆستەرەکان بە ئاسانی';
    return 'Clear cache and posters easily';
  }

  // ─── Manual Sort Settings ────────────────────────────────────────────────

  String get manualSortTitle {
    if (isArabic) return 'ترتيب يدوي';
    if (isKurmanji) return 'Rêzkirina Destî';
    if (isSorani) return 'ڕێکخستنی دەستی';
    return 'Manual Sort';
  }

  String get manualSortSub {
    if (isArabic) return 'إعادة ترتيب القنوات والمجموعات';
    if (isKurmanji) return 'Qenal û koman ji nû ve rêz bike';
    if (isSorani) return 'ڕیزبەندی کەناڵ و گرووپەکان بگۆڕە';
    return 'Reorder channels and groups';
  }

  String get manualSortGroupsTab {
    if (isArabic) return 'المجموعات';
    if (isKurmanji) return 'Kom';
    if (isSorani) return 'گرووپەکان';
    return 'Groups';
  }

  String get manualSortChannelsTab {
    if (isArabic) return 'القنوات';
    if (isKurmanji) return 'Qenal';
    if (isSorani) return 'کەناڵەکان';
    return 'Channels';
  }

  String get manualSortReset {
    if (isArabic) return 'إعادة ضبط';
    if (isKurmanji) return 'Vegerîne';
    if (isSorani) return 'گەڕاندنەوە';
    return 'Reset';
  }

  String get manualSortResetMessage {
    if (isArabic) return 'تم إعادة ضبط الترتيب';
    if (isKurmanji) return 'Rêzbendî hat vegerandin';
    if (isSorani) return 'ڕیزبەندی گەڕێندرایەوە';
    return 'Sort order reset';
  }

  String get manualSortNoGroups {
    if (isArabic) return 'لا توجد مجموعات';
    if (isKurmanji) return 'Ti kom nehatin dîtin';
    if (isSorani) return 'هیچ گرووپێک نەدۆزرایەوە';
    return 'No groups found';
  }

  // ─── World Cup ────────────────────────────────────────────────

  String get wcTitle {
    if (isArabic) return 'كأس العالم FIFA 2026';
    if (isKurmanji) return 'Kûpaya Cîhanê FIFA 2026';
    if (isSorani) return 'مۆندیالی ٢٠٢٦';
    return 'FIFA World Cup 2026';
  }

  String get wcTabLive {
    if (isArabic) return 'مباشر';
    if (isKurmanji) return 'Zindî';
    if (isSorani) return 'ڕاستەوخۆ';
    return 'Live';
  }

  String get wcTabMatches {
    if (isArabic) return 'المباريات';
    if (isKurmanji) return 'Maç';
    if (isSorani) return 'یارییەکان';
    return 'Matches';
  }

  String get wcTabHighlights {
    if (isArabic) return 'الملخصات';
    if (isKurmanji) return 'Kurte';
    if (isSorani) return 'کورتەکان';
    return 'Highlights';
  }

  String get wcNoHighlights {
    if (isArabic) return 'لم يتم العثور على ملخصات';
    if (isKurmanji) return 'Kurteyên maçan nehatin dîtin';
    if (isSorani) return 'هیچ کورتەیەکی یاری نەدۆزرایەوە';
    return 'No match highlights found';
  }

  String get wcAllVideos {
    if (isArabic) return 'الكل';
    if (isKurmanji) return 'Hemî';
    if (isSorani) return 'هەمووی';
    return 'All Videos';
  }

  String get wcGoalsOnly {
    if (isArabic) return 'الأهداف فقط';
    if (isKurmanji) return 'Tenê Gol';
    if (isSorani) return 'تەنها گۆڵەکان';
    return 'Goals Only';
  }

  String get wcHighlightsOnly {
    if (isArabic) return 'الملخصات فقط';
    if (isKurmanji) return 'Tenê Kurte';
    if (isSorani) return 'تەنها کورتەکان';
    return 'Highlights Only';
  }


  String get wcTabGroups {
    if (isArabic) return 'المجموعات';
    if (isKurmanji) return 'Kom';
    if (isSorani) return 'گروپەکان';
    return 'Groups';
  }

  String get wcTabNews {
    if (isArabic) return 'الأخبار';
    if (isKurmanji) return 'Nûçe';
    if (isSorani) return 'هەواڵەکان';
    return 'News';
  }

  String get wcTabScorers {
    if (isArabic) return 'الإحصائيات';
    if (isKurmanji) return 'Amar';
    if (isSorani) return 'ئامارەکان';
    return 'Stats';
  }

  String get wcTabTeams {
    if (isArabic) return 'الفرق';
    if (isKurmanji) return 'Tîm';
    if (isSorani) return 'تیمەکان';
    return 'Teams';
  }

  String get wcTabVenues {
    if (isArabic) return 'الملاعب';
    if (isKurmanji) return 'Yarîgeh';
    if (isSorani) return 'یاریگاکان';
    return 'Venues';
  }

  String get wcYesterday {
    if (isArabic) return 'أمس';
    if (isKurmanji) return 'Duhî';
    if (isSorani) return 'دوێنێ';
    return 'Yesterday';
  }

  String get wcToday {
    if (isArabic) return 'اليوم';
    if (isKurmanji) return 'Îro';
    if (isSorani) return 'ئەمڕۆ';
    return 'Today';
  }

  String get wcTomorrow {
    if (isArabic) return 'غداً';
    if (isKurmanji) return 'Sibê';
    if (isSorani) return 'سبەی';
    return 'Tomorrow';
  }

  String get wcAfterTomorrow {
    if (isArabic) return 'التالي';
    if (isKurmanji) return 'Duyê sibê';
    if (isSorani) return 'دواتر';
    return 'Next';
  }

  String get wcNoMatches {
    if (isArabic) return 'لا توجد مباريات في هذا التاريخ';
    if (isKurmanji) return 'Maç tune ye di vê rojê de';
    if (isSorani) return 'هیچ یارییەک نییە لەم بەروارەدا';
    return 'No matches on this date';
  }

  String get wcNoMatchesFound {
    if (isArabic) return 'لم يتم العثور على مباريات';
    if (isKurmanji) return 'Maç nehat dîtin';
    if (isSorani) return 'هیچ یاری نەدۆزرایەوە';
    return 'No matches found';
  }

  String get wcGroupStandings {
    if (isArabic) return 'ترتيب المجموعة';
    if (isKurmanji) return 'Rêzika Komê';
    if (isSorani) return 'خشتەی گروپ';
    return 'Group Standings';
  }

  String get wcNoGroups {
    if (isArabic) return 'لم يتم العثور على مجموعات';
    if (isKurmanji) return 'Kom nehat dîtin';
    if (isSorani) return 'هیچ گروپێک نەدۆزرایەوە';
    return 'No groups found';
  }

  String get wcNoNews {
    if (isArabic) return 'لا توجد أخبار';
    if (isKurmanji) return 'Nûçe tune ye';
    if (isSorani) return 'هەواڵ بەردەست نییە';
    return 'No news available';
  }

  String get wcNoScorers {
    if (isArabic) return 'لا توجد بيانات';
    if (isKurmanji) return 'Agahî tune ye';
    if (isSorani) return 'هیچ زانیارییەک بەردەست نییە';
    return 'No data available';
  }

  String get wcLive {
    if (isArabic) return 'مباشر';
    if (isKurmanji) return 'ZINDÎ';
    if (isSorani) return 'ڕاستەوخۆ';
    return 'LIVE';
  }

  String get wcUpcoming {
    if (isArabic) return 'قادمة';
    if (isKurmanji) return 'Bê';
    if (isSorani) return 'داهاتوو';
    return 'Upcoming';
  }

  String get wcFinished {
    if (isArabic) return 'انتهت';
    if (isKurmanji) return 'KU';
    if (isSorani) return 'کۆتایی';
    return 'FT';
  }

  String get wcGoals {
    if (isArabic) return 'أهداف';
    if (isKurmanji) return 'Gol';
    if (isSorani) return 'گۆڵ';
    return 'Goals';
  }

  String get wcTeam {
    if (isArabic) return 'فريق';
    if (isKurmanji) return 'Tîm';
    if (isSorani) return 'تیم';
    return 'Team';
  }

  String get wcNewsLabel {
    if (isArabic) return 'أخبار';
    if (isKurmanji) return 'NÛÇE';
    if (isSorani) return 'هەواڵ';
    return 'NEWS';
  }

  String get wcRecently {
    if (isArabic) return 'مؤخراً';
    if (isKurmanji) return 'Vêga';
    if (isSorani) return 'دواواتر';
    return 'Recently';
  }

  String wcTimeAgo(int minutes) {
    if (minutes < 60) {
      if (isArabic) return 'قبل $minutes دقيقة';
      if (isKurmanji) return '${minutes}d berê';
      if (isSorani) return 'پێش $minutes خولەک';
      return '${minutes}m ago';
    }
    final hours = minutes ~/ 60;
    if (hours < 24) {
      if (isArabic) return 'قبل $hours ساعة';
      if (isKurmanji) return '${hours}s berê';
      if (isSorani) return 'پێش $hours کاتژمێر';
      return '${hours}h ago';
    }
    final days = hours ~/ 24;
    if (isArabic) return 'قبل $days يوم';
    if (isKurmanji) return '${days}r berê';
    if (isSorani) return 'پێش $days ڕۆژ';
    return '${days}d ago';
  }

  String get wcViewers {
    if (isArabic) return 'مشاهدون';
    if (isKurmanji) return 'temaşevan';
    if (isSorani) return 'بینەر';
    return 'viewers';
  }

  String get wcNoTeams {
    if (isArabic) return 'لم يتم العثور على فرق';
    if (isKurmanji) return 'Tîm nehatin dîtin';
    if (isSorani) return 'هیچ تیمێک نەدۆزرایەوە';
    return 'No teams found';
  }

  String get wcTournamentStats {
    if (isArabic) return 'إحصائيات البطولة';
    if (isKurmanji) return 'Statîstîkên Tûrnûvayê';
    if (isSorani) return 'ئامارەکانی پاڵەوانێتی';
    return 'Tournament Stats';
  }

  String get wcStatsNotAvailable {
    if (isArabic) return 'الإحصائيات غير متوفرة بعد';
    if (isKurmanji) return 'Statîstîk hê ne berdest in';
    if (isSorani) return 'ئامارەکان هێشتا بەردەست نین';
    return 'Stats not available yet';
  }

  String get wcCapacity {
    if (isArabic) return 'السعة';
    if (isKurmanji) return 'Kapasîte';
    if (isSorani) return 'توانای لەخۆگرتن';
    return 'Capacity';
  }

  String get wcLiveWinProbability {
    if (isArabic) return 'احتمال الفوز المباشر';
    if (isKurmanji) return 'Îhtîmala Serkeftinê ya Zindî';
    if (isSorani) return 'ئەگەری بردنەوەی ڕاستەوخۆ';
    return 'Live Win Probability';
  }

  String get wcDraw {
    if (isArabic) return 'تعادل';
    if (isKurmanji) return 'Beramber';
    if (isSorani) return 'یەکسانبوون';
    return 'Draw';
  }

  String get wcSummary {
    if (isArabic) return 'ملخص';
    if (isKurmanji) return 'Kurte';
    if (isSorani) return 'کورتە';
    return 'Summary';
  }

  String get wcRosters {
    if (isArabic) return 'التشكيلة';
    if (isKurmanji) return 'Kadro';
    if (isSorani) return 'پێکهاتە';
    return 'Rosters';
  }

  String get wcTimeline {
    if (isArabic) return 'الجدول الزمني';
    if (isKurmanji) return 'Rêzbûyer';
    if (isSorani) return 'کاتی ڕووداوەکان';
    return 'Timeline';
  }

  String get wcSubstitutes {
    if (isArabic) return 'البدلاء';
    if (isKurmanji) return 'Yedek';
    if (isSorani) return 'یەدەگەکان';
    return 'Substitutes';
  }

  String get wcManager {
    if (isArabic) return 'المدرب';
    if (isKurmanji) return 'Rêvebir';
    if (isSorani) return 'ڕاهێنەر';
    return 'Manager';
  }

  String get wcSquadRoster {
    if (isArabic) return 'تشكيلة الفريق';
    if (isKurmanji) return 'Kadroyê Tîmê';
    if (isSorani) return 'پێکهاتەی تیم';
    return 'Squad Roster';
  }

  String get wcGoalkeepers {
    if (isArabic) return 'حراس المرمى';
    if (isKurmanji) return 'Goleparêz';
    if (isSorani) return 'گۆڵپارێزەکان';
    return 'Goalkeepers';
  }

  String get wcDefenders {
    if (isArabic) return 'المدافعون';
    if (isKurmanji) return 'Parastvan';
    if (isSorani) return 'بەرگریکارەکان';
    return 'Defenders';
  }

  String get wcMidfielders {
    if (isArabic) return 'لاعبو الوسط';
    if (isKurmanji) return 'Navend';
    if (isSorani) return 'یاریزانانی ناوەڕاست';
    return 'Midfielders';
  }

  String get wcForwards {
    if (isArabic) return 'المهاجمون';
    if (isKurmanji) return 'Êrîşber';
    if (isSorani) return 'هێرشبەرەکان';
    return 'Forwards';
  }

  String get wcNoRosterData {
    if (isArabic) return 'لا توجد بيانات تشكيلة';
    if (isKurmanji) return 'Daneyên kadro tune';
    if (isSorani) return 'هیچ داتایەکی پێکهاتە نییە';
    return 'No roster data available';
  }
  String get updateLater {
    if (isArabic) return 'لاحقاً';
    if (isKurmanji) return 'Paşê';
    if (isSorani) return 'دواتر';
    return 'LATER';
  }

  String get updateAvailable {
    if (isArabic) return 'يتوفر تحديث';
    if (isKurmanji) return 'NÛVEKIRIN HEYE';
    if (isSorani) return 'نوێکردنەوە بەردەستە';
    return 'UPDATE AVAILABLE';
  }

  String updateVersion(String version) {
    if (isArabic) return 'الإصدار $version';
    if (isKurmanji) return 'Guherto $version';
    if (isSorani) return 'وەشانی $version';
    return 'Version $version';
  }

  String updateReleaseNotesEmpty(String original) {
    if (original.isNotEmpty) return original;
    if (isArabic) return 'إصلاح أخطاء وتحسين الأداء.';
    if (isKurmanji) return 'Sererastkirina çewtiyan û baştirkirina performansê.';
    if (isSorani) return 'چارەسەرکردنی کێشەکان و باشترکردنی خێرایی.';
    return 'Bug fixes and performance improvements.';
  }

  String get updateDownload {
    if (isArabic) return 'تحميل التحديث';
    if (isKurmanji) return 'NÛVEKIRINÊ DAXE';
    if (isSorani) return 'دابەزاندنی نوێکردنەوە';
    return 'DOWNLOAD UPDATE';
  }

  String get updateInstall {
    if (isArabic) return 'تثبيت التحديث';
    if (isKurmanji) return 'NÛVEKIRINÊ LÊ BIKE';
    if (isSorani) return 'دامەزراندنی نوێکردنەوە';
    return 'INSTALL UPDATE';
  }

  String get updatePreparing {
    if (isArabic) return 'جاري التحضير...';
    if (isKurmanji) return 'Tê amadekirin...';
    if (isSorani) return 'ئامادەکردن...';
    return 'Preparing...';
  }

  String updateDownloading(String received, String total) {
    if (isArabic) return 'جاري التحميل... $received / $total ميجابايت';
    if (isKurmanji) return 'Tê daxistin... $received / $total MB';
    if (isSorani) return 'لە دابەزاندندایە... $received / $total مێگابایت';
    return 'Downloading... $received / $total MB';
  }

  String get updateDownloadComplete {
    if (isArabic) return 'اكتمل التحميل!';
    if (isKurmanji) return 'Daxistin Temam Bû!';
    if (isSorani) return 'دابەزاندن تەواو بوو!';
    return 'Download Complete!';
  }

  String get updateDownloadFailed {
    if (isArabic) return 'فشل التحميل. اضغط لإعادة المحاولة.';
    if (isKurmanji) return 'Daxistin têk çû. Ji bo dubarekirinê pêl bike.';
    if (isSorani) return 'دابەزاندن سەرکەوتوو نەبوو. دەست لێ بدە بۆ دووبارەکردنەوە.';
    return 'Download failed. Tap to retry.';
  }

  String get subscriptionActiveTitle {
    if (isArabic) return 'الاشتراك نشط';
    if (isKurmanji) return 'Abonetî Çalak e';
    if (isSorani) return 'بەشداریکردن چالاکە';
    return 'Subscription Active';
  }

  String get subscriptionActiveSub {
    if (isArabic) return 'اضغط لإدارة الحساب';
    if (isKurmanji) return 'Dest bide ji bo birêvebirina hesabê';
    if (isSorani) return 'دەست لێ بدە بۆ بەڕێوەبردنی هەژمار';
    return 'Tap to manage account';
  }

  String get sectionInterfaceSub {
    if (isArabic) return 'السمات والألوان والحركات';
    if (isKurmanji) return 'Reng û anîmasyonan';
    if (isSorani) return 'شێوازەکان، ڕەنگەکان و جوڵەکان';
    return 'Themes, gradients, and animations';
  }

  String get sectionPlaybackSub {
    if (isArabic) return 'حجم الفيديو، الترجمة، وتسريع العتاد';
    if (isKurmanji) return 'Mezinahiya vîdyoyê, binnivîs û leza amûran';
    if (isSorani) return 'قەبارەی ڤیدیۆ، ژێرنووس، و خێراکردنی ڕەقەکاڵا';
    return 'Video fit, subtitles, hardware accel';
  }

  String get sectionStorageSub {
    if (isArabic) return 'مسح ذاكرة التخزين المؤقت والمفضلة';
    if (isKurmanji) return 'Paqijkirina kaşê û bijareyan';
    if (isSorani) return 'سڕینەوەی کاش و دڵخوازەکان';
    return 'Clear cache and favorites';
  }

  String get sectionDiagnosticsSub {
    if (isArabic) return 'اختبار السرعة وعرض الشاشة';
    if (isKurmanji) return 'Testa lezê û nîşandana ekranê';
    if (isSorani) return 'پشکنینی خێرایی و نیشاندانی شاشە';
    return 'Speed test and display output';
  }

  String get sectionSupportSub {
    if (isArabic) return 'التحديثات ومعلومات الإصدار وتليجرام';
    if (isKurmanji) return 'Nûvekirin, zanyariyên guhertoyê û Telegram';
    if (isSorani) return 'نوێکردنەوەکان، زانیاری وەشان و تێلیگرام';
    return 'Updates, version info, telegram';
  }
}
