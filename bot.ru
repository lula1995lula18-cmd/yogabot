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
    exit(1)

# ========== КОМАНДА /start ==========
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    keyboard = [
        [InlineKeyboardButton("🎯 Пройти тест", callback_data='start_test')],
        [InlineKeyboardButton("📅 Расписание", callback_data='schedule')],
        [InlineKeyboardButton("💎 Мои курсы", callback_data='courses')],
        [InlineKeyboardButton("❓ Помощь", callback_data='help')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(
        f"Привет, {update.effective_user.first_name}! Я твой цифровой помощник по йоге.\n\n"
        "Выбери действие:",
        reply_markup=reply_markup
    )

# ========== ОБРАБОТЧИКИ КНОПОК ==========
async def button_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    data = query.data
    
    if data == 'start_test':
        await test_1(query, context)
    elif data == 'schedule':
        await show_schedule(query)
    elif data == 'courses':
        await show_courses(query)
    elif data == 'help':
        await show_help(query)

# ========== ТЕСТ ДЛЯ ПОДБОРА КУРСА ==========
async def test_1(query, context):
    keyboard = [
        [InlineKeyboardButton("Снять стресс", callback_data='test_stress')],
        [InlineKeyboardButton("Похудеть", callback_data='test_weight')],
        [InlineKeyboardButton("Улучшить сон", callback_data='test_sleep')],
        [InlineKeyboardButton("Избавиться от боли", callback_data='test_pain')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        "🎯 Какова твоя главная цель?",
        reply_markup=reply_markup
    )

async def test_2(query, context):
    goal = query.data
    context.user_data['goal'] = goal
    
    keyboard = [
        [InlineKeyboardButton("Новичок", callback_data='level_beginner')],
        [InlineKeyboardButton("Опытный", callback_data='level_advanced')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        "📊 Какой у тебя уровень практики?",
        reply_markup=reply_markup
    )

async def test_3(query, context):
    level = query.data
    context.user_data['level'] = level
    
    keyboard = [
        [InlineKeyboardButton("Спина/шея", callback_data='zone_back')],
        [InlineKeyboardButton("Таз/бедра", callback_data='zone_hips')],
        [InlineKeyboardButton("Дыхание", callback_data='zone_breath')],
        [InlineKeyboardButton("Всё ок", callback_data='zone_ok')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        "🎯 Есть ли проблемные зоны?",
        reply_markup=reply_markup
    )

async def show_result(query, context):
    goal = context.user_data.get('goal', '')
    level = context.user_data.get('level', '')
    zone = context.user_data.get('zone', '')
    
    # Логика рекомендации (замените на свои курсы)
    if 'stress' in goal:
        recommendation = "Йога для снятия стресса"
        url = "https://your-site.com/stress-course"
    elif 'weight' in goal:
        recommendation = "Динамическая йога для похудения" 
        url = "https://your-site.com/weight-course"
    elif 'pain' in goal:
        recommendation = "Йога-терапия для спины"
        url = "https://your-site.com/pain-course"
    else:
        recommendation = "Базовый курс медитации"
        url = "https://your-site.com/basic-course"
keyboard = [[InlineKeyboardButton("💎 Получить курс", url=url)]]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        f"✨ Идеально для тебя!\n\n"
        f"**Рекомендация:** {recommendation}\n\n"
        f"Этот курс поможет достичь твоих целей максимально эффективно!",
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )

# ========== ДРУГИЕ ФУНКЦИИ ==========
async def show_schedule(query):
    await query.edit_message_text(
        "📅 **Расписание занятий:**\n\n"
        "ПН/СР/ПТ - 9:00 Утренняя практика\n"
        "ВТ/ЧТ - 19:00 Вечерняя медитация\n"
        "СБ - 11:00 Интенсив",
        parse_mode='Markdown'
    )

async def show_courses(query):
    keyboard = [
        [InlineKeyboardButton("🧘‍♀️ Для начинающих", url="https://your-site.com/beginner")],
        [InlineKeyboardButton("🔥 Для продвинутых", url="https://your-site.com/advanced")],
        [InlineKeyboardButton("💫 Медитации", url="https://your-site.com/meditation")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        "💎 **Мои курсы:**\n\n"
        "Выбери подходящий курс для своего уровня:",
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )

async def show_help(query):
    await query.edit_message_text(
        "❓ **Помощь:**\n\n"
        "По вопросам оплаты и доступа к курсам - @your_username\n"
        "Техподдержка бота - @your_username",
        parse_mode='Markdown'
    )

# ========== ЗАПУСК БОТА ==========
def main():
    application = Application.builder().token(BOT_TOKEN).build()
    
    # Обработчики команд
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(button_handler))
    
    # Обработчики теста
    application.add_handler(CallbackQueryHandler(test_2, pattern='^test_'))
    application.add_handler(CallbackQueryHandler(test_3, pattern='^level_'))
    application.add_handler(CallbackQueryHandler(show_result, pattern='^zone_'))
    
    logger.info("Бот запущен!")
    application.run_polling()

if name == '__main__':
    main()
