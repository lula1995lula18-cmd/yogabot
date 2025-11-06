import os
import logging
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes

# Настройка логирования
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

# Токен бота берется из переменных окружения Render
BOT_TOKEN = os.environ.get('BOT_TOKEN')

if not BOT_TOKEN:
    logger.error("Токен бота не найден! Убедитесь, что переменная BOT_TOKEN установлена в Render.")
    # Вместо exit(1), лучше просто залогировать ошибку и позволить приложению завершиться,
    # но в реальном продакшене лучше оставить exit(1) или raise, чтобы предотвратить запуск без токена.
    # Для этого примера оставим exit(1) как было.
    exit(1)

# ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (КЛАВИАТУРЫ) ==========

def get_main_menu_keyboard():
    """Возвращает InlineKeyboardMarkup для главного меню."""
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("🎯 Пройти тест", callback_data='start_test')],
        [InlineKeyboardButton("📅 Расписание", callback_data='schedule')],
        [InlineKeyboardButton("💎 Мои курсы", callback_data='courses')],
        [InlineKeyboardButton("❓ Помощь", callback_data='help')]
    ])

# ========== КОМАНДА /start (и главное меню) ==========
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Отправляет или редактирует сообщение с главным меню."""
    
    # Определяем, был ли вызов через команду /start или через кнопку "Назад"
    if update.callback_query:
        # Если это CallbackQuery (нажали "Назад"), редактируем предыдущее сообщение
        query = update.callback_query
        await query.answer()
        await query.edit_message_text(
            "Выберите действие:",
            reply_markup=get_main_menu_keyboard()
        )
    else:
        # Если это команда /start, отправляем новое приветственное сообщение
        await update.message.reply_text(
            f"Привет, {update.effective_user.first_name}! Я твой цифровой помощник по йоге.\n\n"
            "Выберите действие:",
            reply_markup=get_main_menu_keyboard()
        )

# ========== ОБРАБОТЧИКИ КНОПОК ==========
async def button_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    data = query.data
    
    if data == 'main_menu':
        # Обработка кнопки "Назад"
        await start(update, context)
    elif data == 'start_test':
        await test_1(query, context)
    elif data == 'schedule':
        await show_schedule(query, context)
    elif data == 'courses':
        await show_courses(query, context)
    elif data == 'help':
        await show_help(query, context)
    elif data.startswith('test_'):
        await test_2(query, context)
    elif data.startswith('level_'):
        await test_3(query, context)
    elif data.startswith('zone_'):
        # Здесь мы сохраняем только часть после префикса для более чистого результата
        context.user_data['zone'] = data.split('_')[1]
        await show_result(query, context)

# ========== ТЕСТ ДЛЯ ПОДБОРА КУРСА ==========
async def test_1(query, context):
    """Первый вопрос теста: Главная цель."""
    keyboard = [
        [InlineKeyboardButton("Снять стресс", callback_data='test_stress')],
        [InlineKeyboardButton("Похудеть", callback_data='test_weight')],
        [InlineKeyboardButton("Улучшить сон", callback_data='test_sleep')],
        [InlineKeyboardButton("Избавиться от боли", callback_data='test_pain')]
    ]
    keyboard.append([InlineKeyboardButton("🔙 Назад", callback_data='main_menu')])
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        "🎯 Какова твоя главная цель?",
        reply_markup=reply_markup
    )

async def test_2(query, context):
    """Второй вопрос теста: Уровень практики."""
    # Сохраняем только часть после префикса
    goal = query.data.split('_')[1]
    context.user_data['goal'] = goal
    
    keyboard = [
        [InlineKeyboardButton("Новичок", callback_data='level_beginner')],
        [InlineKeyboardButton("Опытный", callback_data='level_advanced')]
    ]
    keyboard.append([InlineKeyboardButton("🔙 Назад", callback_data='start_test')]) # Кнопка назад к test_1
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        "📊 Какой у тебя уровень практики?",
        reply_markup=reply_markup
    )

async def test_3(query, context):
    """Третий вопрос теста: Проблемные зоны."""
    # Сохраняем только часть после префикса
    level = query.data.split('_')[1]
    context.user_data['level'] = level
    
    keyboard = [
        [InlineKeyboardButton("Спина/шея", callback_data='zone_back')],
        [InlineKeyboardButton("Таз/бедра", callback_data='zone_hips')],
        [InlineKeyboardButton("Дыхание", callback_data='zone_breath')],
        [InlineKeyboardButton("Всё ок", callback_data='zone_ok')]
    ]
    keyboard.append([InlineKeyboardButton("🔙 Назад", callback_data=f"test_{context.user_data['goal']}")]) # Кнопка назад к test_2
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        "🎯 Есть ли проблемные зоны?",
        reply_markup=reply_markup
    )

async def show_result(query, context):
    """Показывает результат теста и рекомендуемый курс."""
    goal = context.user_data.get('goal', 'sleep') # Добавляем дефолтное значение
    level = context.user_data.get('level', 'beginner')
    zone = context.user_data.get('zone', 'ok')
    
    # Логика рекомендации
    recommendation = "Базовый курс по релаксации"
    url = "https://your-site.com/basic-course"

    if 'stress' == goal:
        recommendation = "Йога для снятия стресса и медитации"
        url = "https://your-site.com/stress-course"
    elif 'weight' == goal:
        recommendation = f"{'Динамическая' if level == 'advanced' else 'Начальная'} йога для похудения" 
        url = "https://your-site.com/weight-course"
    elif 'pain' == goal and 'back' in zone:
        recommendation = "Йога-терапия для здоровой спины и шеи"
        url = "https://your-site.com/pain-course"
    elif 'sleep' == goal:
        recommendation = "Вечерняя йога и практики для улучшения сна"
        url = "https://your-site.com/sleep-course"
    
    keyboard = [
        [InlineKeyboardButton("💎 Получить курс", url=url)],
        [InlineKeyboardButton("🔙 В главное меню", callback_data='main_menu')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        f"✨ Идеально для тебя!\n\n"
        f"**Твои параметры:** Цель: `{goal}`, Уровень: `{level}`, Зона: `{zone}`.\n\n"
        f"**Рекомендация:** {recommendation}\n\n"
        f"Этот курс поможет достичь твоих целей максимально эффективно!",
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )
    # Очищаем данные пользователя после завершения теста
    context.user_data.clear()


# ========== ДРУГИЕ ФУНКЦИИ ==========
async def show_schedule(query, context):
    """Показывает расписание."""
    keyboard = [[InlineKeyboardButton("🔙 Назад", callback_data='main_menu')]]
    reply_markup = InlineKeyboardMarkup(keyboard)

    await query.edit_message_text(
        "📅 **Расписание занятий:**\n\n"
        "ПН/СР/ПТ - 9:00 Утренняя практика\n"
        "ВТ/ЧТ - 19:00 Вечерняя медитация\n"
        "СБ - 11:00 Интенсив\n\n"
        "Подробности смотри на сайте.",
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )

async def show_courses(query, context):
    """Показывает список курсов."""
    keyboard = [
        [InlineKeyboardButton("🧘‍♀️ Для начинающих", url="https://your-site.com/beginner")],
        [InlineKeyboardButton("🔥 Для продвинутых", url="https://your-site.com/advanced")],
        [InlineKeyboardButton("💫 Медитации", url="https://your-site.com/meditation")],
        [InlineKeyboardButton("🔙 Назад", callback_data='main_menu')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        "💎 **Мои курсы:**\n\n"
        "Выбери подходящий курс для своего уровня:",
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )

async def show_help(query, context):
    """Показывает информацию для связи."""
    keyboard = [[InlineKeyboardButton("🔙 Назад", callback_data='main_menu')]]
    reply_markup = InlineKeyboardMarkup(keyboard)

    await query.edit_message_text(
        "❓ **Помощь:**\n\n"
        "По вопросам оплата и доступа к курсам - @your_username\n"
        "Техподдержка бота - @your_username",
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )

# ========== ЗАПУСК БОТА ==========
def main():
    """Запуск бота."""
    application = Application.builder().token(BOT_TOKEN).build()
    
    # Обработчики команд
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(button_handler))
    
    logger.info("Бот запущен и использует run_polling!")
    # run_polling подходит для запуска на Render в небольших проектах или локально
    application.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == '__main__':
    main()
