import 'dart:async';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Onboarding
      'welcome': 'Welcome to Tooler',
      'manage_tools': 'Manage your construction tools efficiently',
      'track_tools': 'Track Tools',
      'move_between': 'Move tools between construction objects',
      'work_offline': 'Work Offline',
      'sync_data': 'Sync data when internet is available',
      'export_share': 'Export & Share',
      'create_reports': 'Create PDF reports and share inventory',
      'next': 'Next',
      'back': 'Back',
      'get_started': 'Get Started',

      // Authentication
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'remember_me': 'Remember Me',
      'sign_in_failed': 'Sign in failed. Check your credentials.',
      'sign_up_failed': 'Sign up failed. Try again.',
      'fill_all_fields': 'Please fill all fields',
      'no_account': 'Don\'t have an account? Sign Up',
      'has_account': 'Already have an account? Sign In',

      // Navigation
      'tools': 'Tools',
      'objects': 'Objects',
      'move': 'Move',
      'favorites': 'Favorites',
      'profile': 'Profile',

      // Settings
      'dark_mode': 'Dark Mode',
      'export_pdf': 'Export to PDF',
      'take_screenshot': 'Take Screenshot',
      'sign_out': 'Sign Out',

      // Empty States
      'no_tools': 'No tools yet',
      'add_first_tool': 'Add your first tool to get started',
      'no_objects': 'No construction objects',
      'add_first_site': 'Add your first construction site',
      'no_favorites': 'No favorite tools',
      'mark_favorites': 'Mark tools as favorites to see them here',

      // User Info
      'construction_manager': 'Construction Manager',
      'guest': 'Guest',

      // Actions
      'tool_moved': 'Tool moved successfully',
      'screenshot_saved': 'Screenshot saved',
      'search': 'Search',
      'search_hint': 'Search...',
      'pdf_preview': 'PDF Preview',
      'share': 'Share',
      'print': 'Print',
      'generating_pdf': 'Generating PDF...',
      'pdf_error': 'Error generating PDF',

      // Tool Management
      'add_tool': 'Add New Tool',
      'edit_tool': 'Edit Tool',
      'tool_name': 'Tool Name',
      'description': 'Description',
      'brand': 'Brand',
      'unique_id': 'Unique ID',
      'add': 'Add',
      'save': 'Save',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'duplicate': 'Duplicate',
      'delete': 'Delete',
      'confirm_delete': 'Confirm Delete',
      'delete_warning':
          'Are you sure you want to delete this item? This action cannot be undone.',
      'close': 'Close',
      'location': 'Location',
      'select_image_source': 'Select Image Source',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'remove': 'Remove',
      'unassigned': 'Unassigned',
      'select_destination': 'Select destination:',

      // Object Management
      'add_object': 'Add New Object',
      'edit_object': 'Edit Object',
      'object_name': 'Object Name',

      // Tool Details
      'id': 'ID',
      'favorite': 'Favorite',
      'yes': 'Yes',
      'no': 'No',
      'location_history': 'Location History',
      'tools_at_location': 'Tools at this location:',

      // Status Messages
      'tool_added': 'Tool added successfully',
      'tool_updated': 'Tool updated successfully',
      'tool_deleted': 'Tool deleted successfully',
      'object_added': 'Object added successfully',
      'object_updated': 'Object updated successfully',
      'object_deleted': 'Object deleted successfully',
      'please_fill_required_fields': 'Please fill required fields',
      'please_enter_object_name': 'Please enter object name',

      // Dates
      'created': 'Created',
      'updated': 'Updated',
      'previous_location': 'Previous Location',
    },
    'ru': {
      // Onboarding
      'welcome': 'Добро пожаловать в Tooler',
      'manage_tools': 'Эффективно управляйте строительными инструментами',
      'track_tools': 'Отслеживание инструментов',
      'move_between': 'Перемещайте инструменты между объектами',
      'work_offline': 'Работа оффлайн',
      'sync_data': 'Синхронизация данных при наличии интернета',
      'export_share': 'Экспорт и обмен',
      'create_reports': 'Создание PDF отчетов и обмен инвентарем',
      'next': 'Далее',
      'back': 'Назад',
      'get_started': 'Начать',

      // Authentication
      'sign_in': 'Войти',
      'sign_up': 'Зарегистрироваться',
      'email': 'Электронная почта',
      'password': 'Пароль',
      'remember_me': 'Запомнить меня',
      'sign_in_failed': 'Ошибка входа. Проверьте учетные данные.',
      'sign_up_failed': 'Ошибка регистрации. Попробуйте еще раз.',
      'fill_all_fields': 'Пожалуйста, заполните все поля',
      'no_account': 'Нет аккаунта? Зарегистрироваться',
      'has_account': 'Уже есть аккаунт? Войти',

      // Navigation
      'tools': 'Инструменты',
      'objects': 'Объекты',
      'move': 'Переместить',
      'favorites': 'Избранное',
      'profile': 'Профиль',

      // Settings
      'dark_mode': 'Темная тема',
      'export_pdf': 'Экспорт в PDF',
      'take_screenshot': 'Сделать скриншот',
      'sign_out': 'Выйти',

      // Empty States
      'no_tools': 'Инструментов пока нет',
      'add_first_tool': 'Добавьте первый инструмент',
      'no_objects': 'Строительных объектов нет',
      'add_first_site': 'Добавьте первую строительную площадку',
      'no_favorites': 'Нет избранных инструментов',
      'mark_favorites': 'Отмечайте инструменты как избранные',

      // User Info
      'construction_manager': 'Строительный менеджер',
      'guest': 'Гость',

      // Actions
      'tool_moved': 'Инструмент успешно перемещен',
      'screenshot_saved': 'Скриншот сохранен',
      'search': 'Поиск',
      'search_hint': 'Поиск...',
      'pdf_preview': 'Предпросмотр PDF',
      'share': 'Поделиться',
      'print': 'Печать',
      'generating_pdf': 'Генерация PDF...',
      'pdf_error': 'Ошибка генерации PDF',

      // Tool Management
      'add_tool': 'Добавить новый инструмент',
      'edit_tool': 'Редактировать инструмент',
      'tool_name': 'Название инструмента',
      'description': 'Описание',
      'brand': 'Бренд',
      'unique_id': 'Уникальный ID',
      'add': 'Добавить',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'edit': 'Редактировать',
      'duplicate': 'Дублировать',
      'delete': 'Удалить',
      'confirm_delete': 'Подтверждение удаления',
      'delete_warning':
          'Вы уверены, что хотите удалить этот элемент? Это действие нельзя отменить.',
      'close': 'Закрыть',
      'location': 'Местоположение',
      'select_image_source': 'Выберите источник изображения',
      'gallery': 'Галерея',
      'camera': 'Камера',
      'remove': 'Удалить',
      'unassigned': 'Не назначено',
      'select_destination': 'Выберите пункт назначения:',

      // Object Management
      'add_object': 'Добавить новый объект',
      'edit_object': 'Редактировать объект',
      'object_name': 'Название объекта',

      // Tool Details
      'id': 'ID',
      'favorite': 'Избранное',
      'yes': 'Да',
      'no': 'Нет',
      'location_history': 'История перемещений',
      'tools_at_location': 'Инструменты в этом месте:',

      // Status Messages
      'tool_added': 'Инструмент успешно добавлен',
      'tool_updated': 'Инструмент успешно обновлен',
      'tool_deleted': 'Инструмент успешно удален',
      'object_added': 'Объект успешно добавлен',
      'object_updated': 'Объект успешно обновлен',
      'object_deleted': 'Объект успешно удален',
      'please_fill_required_fields': 'Пожалуйста, заполните обязательные поля',
      'please_enter_object_name': 'Пожалуйста, введите название объекта',

      // Dates
      'created': 'Создано',
      'updated': 'Обновлено',
      'previous_location': 'Предыдущее местоположение',
    },
  };

  String? translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key];
  }

  // Onboarding
  String get welcome => translate('welcome')!;
  String get manageTools => translate('manage_tools')!;
  String get trackTools => translate('track_tools')!;
  String get moveBetween => translate('move_between')!;
  String get workOffline => translate('work_offline')!;
  String get syncData => translate('sync_data')!;
  String get exportShare => translate('export_share')!;
  String get createReports => translate('create_reports')!;
  String get next => translate('next')!;
  String get back => translate('back')!;
  String get getStarted => translate('get_started')!;

  // Authentication
  String get signIn => translate('sign_in')!;
  String get signUp => translate('sign_up')!;
  String get email => translate('email')!;
  String get password => translate('password')!;
  String get rememberMe => translate('remember_me')!;
  String get signInFailed => translate('sign_in_failed')!;
  String get signUpFailed => translate('sign_up_failed')!;
  String get fillAllFields => translate('fill_all_fields')!;
  String get noAccount => translate('no_account')!;
  String get hasAccount => translate('has_account')!;

  // Navigation
  String get tools => translate('tools')!;
  String get objects => translate('objects')!;
  String get move => translate('move')!;
  String get favorites => translate('favorites')!;
  String get profile => translate('profile')!;

  // Settings
  String get darkMode => translate('dark_mode')!;
  String get exportPdf => translate('export_pdf')!;
  String get takeScreenshot => translate('take_screenshot')!;
  String get signOut => translate('sign_out')!;

  // Empty States
  String get noTools => translate('no_tools')!;
  String get addFirstTool => translate('add_first_tool')!;
  String get noObjects => translate('no_objects')!;
  String get addFirstSite => translate('add_first_site')!;
  String get noFavorites => translate('no_favorites')!;
  String get markFavorites => translate('mark_favorites')!;

  // User Info
  String get constructionManager => translate('construction_manager')!;
  String get guest => translate('guest')!;

  // Actions
  String get toolMoved => translate('tool_moved')!;
  String get screenshotSaved => translate('screenshot_saved')!;
  String get search => translate('search')!;
  String get searchHint => translate('search_hint')!;
  String get pdfPreview => translate('pdf_preview')!;
  String get share => translate('share')!;
  String get print => translate('print')!;
  String get generatingPdf => translate('generating_pdf')!;
  String get pdfError => translate('pdf_error')!;

  // Tool Management
  String get addTool => translate('add_tool')!;
  String get editTool => translate('edit_tool')!;
  String get toolName => translate('tool_name')!;
  String get description => translate('description')!;
  String get brand => translate('brand')!;
  String get uniqueId => translate('unique_id')!;
  String get add => translate('add')!;
  String get save => translate('save')!;
  String get cancel => translate('cancel')!;
  String get edit => translate('edit')!;
  String get duplicate => translate('duplicate')!;
  String get delete => translate('delete')!;
  String get confirmDelete => translate('confirm_delete')!;
  String get deleteWarning => translate('delete_warning')!;
  String get close => translate('close')!;
  String get location => translate('location')!;
  String get selectImageSource => translate('select_image_source')!;
  String get gallery => translate('gallery')!;
  String get camera => translate('camera')!;
  String get remove => translate('remove')!;
  String get unassigned => translate('unassigned')!;
  String get selectDestination => translate('select_destination')!;

  // Object Management
  String get addObject => translate('add_object')!;
  String get editObject => translate('edit_object')!;
  String get objectName => translate('object_name')!;

  // Tool Details
  String get id => translate('id')!;
  String get favorite => translate('favorite')!;
  String get yes => translate('yes')!;
  String get no => translate('no')!;
  String get locationHistory => translate('location_history')!;
  String get toolsAtLocation => translate('tools_at_location')!;

  // Status Messages
  String get toolAdded => translate('tool_added')!;
  String get toolUpdated => translate('tool_updated')!;
  String get toolDeleted => translate('tool_deleted')!;
  String get objectAdded => translate('object_added')!;
  String get objectUpdated => translate('object_updated')!;
  String get objectDeleted => translate('object_deleted')!;
  String get pleaseFillRequiredFields =>
      translate('please_fill_required_fields')!;
  String get pleaseEnterObjectName => translate('please_enter_object_name')!;

  // Dates
  String get created => translate('created')!;
  String get updated => translate('updated')!;
  String get previousLocation => translate('previous_location')!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
