# MenoSync — сценарии ручного тестирования (день за днём)

## Как использовать этот документ

- **Отличие от Demo A–D:** там данные были "реалистично зашумлены" для показа инвесторам/юзерам. Здесь наоборот — числа **специально чистые и детерминированные**, чтобы результат на экране можно было посчитать в столбик и сразу увидеть расхождение.
- **Шкалы значений (важно — три разные шкалы, не одна):**
- Severity симптомов и триггеров — целое число **1–3**.
- Длительность симптомов и триггеров (например, длительность прилива, длительность упражнения) — всегда **кратна 5 минутам** (5, 10, 15, 20, ...), не поминутно.
- Sleep quality — отдельная шкала **1–5**, вместе со значением длительности сна. Сейчас вводится **только через Calendar view**, не через основной daily Quick Log (см. отдельный промпт на добавление этого в Quick Log).
- Mood & Well-being — отдельное поле: одна из **6 категорий** (Great/Good/Okay/Low/Anxious/Stressed) + score **1–5** для выбранной категории. Тоже сейчас только через Calendar view.
- Каждый сценарий ниже оформлен как таблица "день за днём" (как Сценарий 1) — вводить построчно.
- Данные вводятся задним числом (retroactive-логирование) за один присест — не нужно ждать реальные дни.
- **Критично:** последний день каждого сценария ("День N") должен по факту совпадать с реальной сегодняшней датой в момент ввода. Иначе всё, что привязано к "сегодня" (обратный отсчёт HRT before/after, готовность Passport), посчитается неправильно не по вине аналитики, а из-за даты.
- Пороговые правила (7/14 событий, 14 дней, 30 дней) — задокументированы в domain rules, поэтому по ним даю точные ожидания.
- "Среднее severity" на Home/Tracker — даю ожидаемое число при допущении простого равновзвешенного среднего по залогированным симптомам. Формула агрегации нигде явно не задокументирована — если число не совпадёт, это повод зафиксировать формулу, а не автоматически баг.
- Процент корреляции (Pearson) — точный % вручную не посчитать без симуляции. Там, где важен порог 70%, данные заложены с максимальным доступным контрастом на шкале 1–3 (1 vs 3), чтобы результат надёжно оказался по нужную сторону порога.
- Sleep и Mood в таблицах ниже держатся на постоянном нейтральном значении везде, где они не являются предметом самой проверки (единственное исключение — Sleep quality в Сценарии 5, где она специально меняется для проверки тренда "Worsening"). Это осознанное упрощение, а не забытые данные.
- Экраны с уже известными проблемами (Patterns — статичный текст, "What Affects You"/AI Insights — застревают на "Keep logging" даже при достаточных данных, Weekly Trends не тапаются, логика "days to go" на Passport) — совпадение с этим поведением подтверждает уже задокументированный баг, а не новую находку.

---

## Что проверять в каждом месте, где есть аналитика

Формат по каждому месту: что должно отображаться → каким сценарием проверять → текущий статус.

### 1. Home · Daily Insight

- **Ожидается:** среднее severity по симптомам, залогированным именно сегодня; при отсутствии логов сегодня — явный no-data стейт, не ложный ноль и не краш.
- **Проверять:** Сценарий 1, День 7.
- **Статус:** формула агрегации не задокументирована — расхождение с равновзвешенным средним = повод зафиксировать формулу, не сразу баг.

### 2. Home · Weekly Insight

- **Ожидается:** среднее за 7 дней + consistency (дней залогировано / 7).
- **Проверять:** Сценарий 1 целиком (7/7 = 100%); Сценарий 6, последние 7 дней (Дни 54–60, залогированы только 59–60 → consistency 2/7).
- **Статус:** та же оговорка по формуле среднего.

### 3. Tracker · Patterns

- **Ожидается сейчас:** известный баг — статичный текст независимо от датасета.
- **Проверять:** любой сценарий — одинаковый текст на Сценариях 1 и 5 (совершенно разные данные) подтверждает баг.
- **Статус:** ⚠️ BLOCKED — логика не специфицирована.

### 4. Tracker · Weekly Trends (2 карточки: symptom intensity, sleep quality)

- **Ожидается:** реальный недельный агрегат за текущую неделю.
- **Проверять:** Сценарий 5 — ступенька joint pain/sleep quality на Дне 31; Сценарий 3 — падение частоты hot flash на Дне 15.
- **Статус:** тап по карточке — см. Trend Detail (п.10).

### 5. Tracker · Personalized Insight

- **Ожидается сейчас:** известный баг — статичный текст.
- **Статус:** ⚠️ BLOCKED.

### 6. Insights · Most Frequent / Severity Trend

- **Проверять:** Most Frequent — Сценарий 7; "Stable" — Сценарий 4 (флэт severity 2); "Worsening" — Сценарий 5; "Improving" — Сценарий 3; период 7/30/90 — под-окна Сценариев 5/6.
- **Статус:** уже работает на реальных данных — регрессионная проверка.

### 7. Insights · What Affects You?

- **Проверять:** Сценарий 4 (карточка без чипа), Сценарий 5 (обе карточки, одна с чипом), Сценарий 11 (карточка без чипа и без негативного текста).
- **Статус:** ⚠️ известный баг — застряло на "Keep logging".

### 8. Insights · AI Correlations & HRT Impact (карточка)

- **Проверять:** обе половины отдельно на Сценариях 2/3/6 (permanent-gate / разблокировано / mid-countdown).
- **Статус:** корреляционная часть — тот же баг, что в п.7; HRT-impact часть гейтится независимо.

### 9. AI Insights page

- **Проверять:** Сценарий 5 — обе карточки должны совпадать с тизером на Insights.
- **Статус:** тот же баг, что в п.7.

### 10. Trend Detail

- **Статус:** ⚠️ BLOCKED — целевой экран не определён.

### 11. Symptom Detail

- **Статус:** ⚠️ BLOCKED — точка входа не решена.

---

## Сценарий 1 — 7 дней — «Пол» (везде недостаточно данных)

**Условия:** Менопауза, HRT — Estradiol patch 50mcg, ежедневно, начат в День 1. Без смены дозы.

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1 | 50mcg ✓ | HF 2 (10 мин), NS 1, Anxiety 1 | — | 6ч / 3 | Good / 4 |
| 2 | 50mcg ✓ | HF 2 (10 мин), NS 1, Anxiety 3 | Stress | 6ч / 3 | Stressed / 2 |
| 3 | 50mcg ✓ | HF 2 (10 мин), NS 1, Anxiety 1 | — | 6ч / 3 | Good / 4 |
| 4 | 50mcg ✓ | HF 2 (10 мин), NS 1, Anxiety 3 | Stress | 6ч / 3 | Stressed / 2 |
| 5 | 50mcg ✓ | HF 2 (10 мин), NS 1, Anxiety 1 | — | 6ч / 3 | Good / 4 |
| 6 | 50mcg ✓ | HF 2 (10 мин), NS 1, Anxiety 3 | Stress | 6ч / 3 | Stressed / 2 |
| 7 | 50mcg ✓ | HF 2 (10 мин), NS 1, Anxiety 1 | — | 6ч / 3 | Good / 4 |

**Ожидаемый результат**

- Adherence: 7/7 = 100%
- Home Daily Insight (день 7): среднее по HF2/NS1/Anxiety1 = **1.33**
- Home Weekly Insight: consistency **7/7 = 100%**
- HRT before/after: **не предлагается вообще** — смены дозы не было ни разу
- Корреляция Stress→Anxiety: ровно **3 парных события** → прогресс "3 из 7"
- Passport: заблокирован, «23 дня осталось» (30−7)

---

## Сценарий 2 — 15 дней — HRT: недостижимый порог (обе стороны \< 14 дней)

**Условия:** Менопауза, Estradiol 50mcg Дни 1–7, смена на 75mcg **в День 8**. Триггеров нет намеренно.

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1–7 | 50mcg ✓ | HF ×5 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 8 | 75mcg ✓ ← divider | HF ×2 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 9–15 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |

**Ожидаемый результат**

- Before-окно Дни 1–7 (7 записей) — **навсегда останется 7** (это прошедшая история)
- After-окно Дни 8–15 (8 записей)
- Before/after: **заблокировано**, и физически не может разблокироваться для этой смены — проверить, что приложение не показывает вводящий в заблуждение обратный отсчёт
- Passport: заблокирован, «15 дней осталось»

---

## Сценарий 3 — 30 дней — HRT: точная граница 14/14 дней + умеренная корреляция

**Условия:** Estradiol 50mcg Дни 1–14, смена на 75mcg **в День 15**.

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1–2 | 50mcg ✓ | HF ×6 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 3 | 50mcg ✓ | HF ×6 (сев.2, 10 мин) | Wine | 6.5ч / 3 | Okay / 3 |
| 4 | 50mcg ✓ | HF ×9 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 5 | 50mcg ✓ | HF ×6 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 6 | 50mcg ✓ | HF ×6 (сев.2, 10 мин) | Wine | 6.5ч / 3 | Okay / 3 |
| 7 | 50mcg ✓ | HF ×9 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 8 | 50mcg ✓ | HF ×6 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 9 | 50mcg ✓ | HF ×6 (сев.2, 10 мин) | Wine | 6.5ч / 3 | Okay / 3 |
| 10 | 50mcg ✓ | HF ×9 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 11 | 50mcg ✓ | HF ×6 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 12 | 50mcg ✓ | HF ×6 (сев.2, 10 мин) | Wine | 6.5ч / 3 | Okay / 3 |
| 13 | 50mcg ✓ | HF ×9 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 14 | 50mcg ✓ | HF ×6 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 15 | 75mcg ✓ ← divider | HF ×2 (сев.2, 10 мин) | Wine | 6.5ч / 3 | Okay / 3 |
| 16 | 75mcg ✓ | HF ×5 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 17 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 18 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | Wine | 6.5ч / 3 | Okay / 3 |
| 19 | 75mcg ✓ | HF ×5 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 20 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 21 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | Wine | 6.5ч / 3 | Okay / 3 |
| 22 | 75mcg ✓ | HF ×5 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 23 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 24 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | Wine | 6.5ч / 3 | Okay / 3 |
| 25 | 75mcg ✓ | HF ×5 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 26 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 27 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | Wine | 6.5ч / 3 | Okay / 3 |
| 28 | 75mcg ✓ | HF ×5 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |
| 29–30 | 75mcg ✓ | HF ×2 (сев.2, 10 мин) | — | 6.5ч / 3 | Okay / 3 |

**Ожидаемый результат**

- Before-окно = ровно 14 дней → должно засчитаться как достаточное
- At День 30: before/after разблокировано. Средняя частота before ≈ **6.86/день**, after ≈ **2.94/день** (падение \~57%)
- Wine→HF: **9 парных событий** → карточка отображается, без чипа (9\<14)
- Passport: ровно 30 дней данных → разблокируется именно сейчас

---

## Сценарий 4 — 30 дней — Перименопауза без HRT, граница ровно 7 событий

**Условия:** Перименопауза, HRT не подключён вообще.

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1–3 | — (no HRT) | HF 2, Anxiety 1, Bleeding (medium) | — | 6.5ч / 3 | Okay / 3 |
| 4 | — (no HRT) | HF 2, Anxiety 1 | Stress | 6.5ч / 3 | Okay / 3 |
| 5 | — (no HRT) | HF 2, Anxiety 3 | — | 6.5ч / 3 | Anxious / 2 |
| 6–7 | — (no HRT) | HF 2, Anxiety 1 | — | 6.5ч / 3 | Okay / 3 |
| 8 | — (no HRT) | HF 2, Anxiety 1 | Stress | 6.5ч / 3 | Okay / 3 |
| 9 | — (no HRT) | HF 2, Anxiety 3 | — | 6.5ч / 3 | Anxious / 2 |
| 10–11 | — (no HRT) | HF 2, Anxiety 1 | — | 6.5ч / 3 | Okay / 3 |
| 12 | — (no HRT) | HF 2, Anxiety 1 | Stress | 6.5ч / 3 | Okay / 3 |
| 13 | — (no HRT) | HF 2, Anxiety 3 | — | 6.5ч / 3 | Anxious / 2 |
| 14 | — (no HRT) | HF 2, Anxiety 1 | — | 6.5ч / 3 | Okay / 3 |
| 15 | — (no HRT) | HF 2, Anxiety 1, Bleeding (light) | — | 6.5ч / 3 | Okay / 3 |
| 16 | — (no HRT) | HF 2, Anxiety 1, Bleeding (light) | Stress | 6.5ч / 3 | Okay / 3 |
| 17 | — (no HRT) | HF 2, Anxiety 3 | — | 6.5ч / 3 | Anxious / 2 |
| 18–19 | — (no HRT) | HF 2, Anxiety 1 | — | 6.5ч / 3 | Okay / 3 |
| 20 | — (no HRT) | HF 2, Anxiety 1 | Stress | 6.5ч / 3 | Okay / 3 |
| 21 | — (no HRT) | HF 2, Anxiety 3 | — | 6.5ч / 3 | Anxious / 2 |
| 22–23 | — (no HRT) | HF 2, Anxiety 1 | — | 6.5ч / 3 | Okay / 3 |
| 24 | — (no HRT) | HF 2, Anxiety 1 | Stress | 6.5ч / 3 | Okay / 3 |
| 25 | — (no HRT) | HF 2, Anxiety 3 | — | 6.5ч / 3 | Anxious / 2 |
| 26–27 | — (no HRT) | HF 2, Anxiety 1 | — | 6.5ч / 3 | Okay / 3 |
| 28 | — (no HRT) | HF 2, Anxiety 1 | Stress | 6.5ч / 3 | Okay / 3 |
| 29 | — (no HRT) | HF 2, Anxiety 3 | — | 6.5ч / 3 | Anxious / 2 |
| 30 | — (no HRT) | HF 2, Anxiety 1 | — | 6.5ч / 3 | Okay / 3 |

**Ожидаемый результат**

- Оба кровотечения (Дни 1–3 medium, Дни 15–16 light) отображаются без предупреждения о "нетипичном" цикле
- Модуль HRT остаётся "не настроен"
- Stress→Anxiety: ровно **7 парных событий** — граничная проверка ("≥7" включает 7), без чипа (7\<14)
- Passport: ровно 30 залогированных дней → разблокирован; «Current HRT» — пусто/None
- Hot flash: флэт severity 2 → тренд **"Stable"**

---

## Сценарий 5 — 60 дней — Постменопауза, стабильная HRT, high-confidence + позитивная корреляция

**Условия:** Постменопауза, один стабильный препарат все 60 дней, без смены дозы. Пропуски приёма — Дни 20 и 45.

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1 | ✓ | HF sev.1 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 2 | ✓ | HF sev.1 (5 мин), Joint pain 2 | Exercise | 6ч / 4 | Good / 4 |
| 3 | ✓ | HF sev.1 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 4 | ✓ | HF sev.1 (10 мин), Joint pain 2 | Wine | 6ч / 4 | Good / 4 |
| 5 | ✓ | HF sev.3 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 6 | ✓ | HF sev.1 (5 мин), Joint pain 2 | Exercise | 6ч / 4 | Good / 4 |
| 7 | ✓ | HF sev.1 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 8 | ✓ | HF sev.1 (10 мин), Joint pain 2 | Wine | 6ч / 4 | Good / 4 |
| 9 | ✓ | HF sev.3 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 10–11 | ✓ | HF sev.1 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 12 | ✓ | HF sev.1 (10 мин), Joint pain 2 | Wine | 6ч / 4 | Good / 4 |
| 13 | ✓ | HF sev.3 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 14 | ✓ | HF sev.1 (5 мин), Joint pain 2 | Exercise | 6ч / 4 | Good / 4 |
| 15 | ✓ | HF sev.1 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 16 | ✓ | HF sev.1 (10 мин), Joint pain 2 | Wine | 6ч / 4 | Good / 4 |
| 17 | ✓ | HF sev.3 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 18 | ✓ | HF sev.1 (5 мин), Joint pain 2 | Exercise | 6ч / 4 | Good / 4 |
| 19 | ✓ | HF sev.1 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 20 | ✗ (missed) | HF sev.1 (10 мин), Joint pain 2 | Wine | 6ч / 4 | Good / 4 |
| 21 | ✓ | HF sev.3 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 22–23 | ✓ | HF sev.1 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 24 | ✓ | HF sev.1 (10 мин), Joint pain 2 | Wine | 6ч / 4 | Good / 4 |
| 25 | ✓ | HF sev.3 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 26 | ✓ | HF sev.1 (5 мин), Joint pain 2 | Exercise | 6ч / 4 | Good / 4 |
| 27 | ✓ | HF sev.1 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 28 | ✓ | HF sev.1 (10 мин), Joint pain 2 | Wine | 6ч / 4 | Good / 4 |
| 29 | ✓ | HF sev.3 (10 мин), Joint pain 2 | — | 6ч / 4 | Good / 4 |
| 30 | ✓ | HF sev.1 (5 мин), Joint pain 2 | Exercise | 6ч / 4 | Good / 4 |
| 31 | ✓ | HF sev.1 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 32 | ✓ | HF sev.1 (10 мин), Joint pain 3 | Wine | 6ч / 2 | Low / 2 |
| 33 | ✓ | HF sev.3 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 34–35 | ✓ | HF sev.1 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 36 | ✓ | HF sev.1 (10 мин), Joint pain 3 | Wine | 6ч / 2 | Low / 2 |
| 37 | ✓ | HF sev.3 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 38 | ✓ | HF sev.1 (5 мин), Joint pain 3 | Exercise | 6ч / 2 | Low / 2 |
| 39 | ✓ | HF sev.1 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 40 | ✓ | HF sev.1 (10 мин), Joint pain 3 | Wine | 6ч / 2 | Low / 2 |
| 41 | ✓ | HF sev.3 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 42 | ✓ | HF sev.1 (5 мин), Joint pain 3 | Exercise | 6ч / 2 | Low / 2 |
| 43 | ✓ | HF sev.1 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 44 | ✓ | HF sev.1 (10 мин), Joint pain 3 | Wine | 6ч / 2 | Low / 2 |
| 45 | ✗ (missed) | HF sev.3 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 46–47 | ✓ | HF sev.1 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 48 | ✓ | HF sev.1 (10 мин), Joint pain 3 | Wine | 6ч / 2 | Low / 2 |
| 49 | ✓ | HF sev.3 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 50 | ✓ | HF sev.1 (5 мин), Joint pain 3 | Exercise | 6ч / 2 | Low / 2 |
| 51 | ✓ | HF sev.1 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 52 | ✓ | HF sev.1 (10 мин), Joint pain 3 | Wine | 6ч / 2 | Low / 2 |
| 53 | ✓ | HF sev.3 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 54 | ✓ | HF sev.1 (5 мин), Joint pain 3 | Exercise | 6ч / 2 | Low / 2 |
| 55 | ✓ | HF sev.1 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 56 | ✓ | HF sev.1 (10 мин), Joint pain 3 | Wine | 6ч / 2 | Low / 2 |
| 57 | ✓ | HF sev.3 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |
| 58–60 | ✓ | HF sev.1 (10 мин), Joint pain 3 | — | 6ч / 2 | Low / 2 |

**Ожидаемый результат**

- Wine→HF severity: **14 парных событий**, контраст 1 vs 3 (максимальный на шкале 1–3) → чип **"High confidence"**
- Exercise→HF duration: **10 парных событий** (10 мин база → 5 мин в день упражнения), позитивный стиль, без чипа (10\<14)
- Joint pain 2→3 и Sleep quality 4→2: чёткая ступенька на Дне 31 → тренд **"Worsening"**
- Adherence: 58/60 ≈ **96.7%**, 2 флага missed dose (Дни 20, 45)

---

## Сценарий 6 — 60 дней — Разреженное логирование, logged days ≠ calendar days

**Условия:** Хирургическая менопауза, HRT (Estradiol) с Дня 1. Все дни, отсутствующие в таблице (8–15, 21–30, 36–45, 53–58), — пропуск: НИЧЕГО не вводится (ни симптомов, ни HRT статуса).

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 2 | 50mcg ✓ | HF 2, Anxiety 1 | Stress | 6ч / 3 | Okay / 3 |
| 3 | 50mcg ✓ | HF 2, Anxiety 3 | — | 6ч / 3 | Okay / 3 |
| 4 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 5 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 6 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 7 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 16 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 17 | 50mcg ✓ | HF 2, Anxiety 1 | Stress | 6ч / 3 | Okay / 3 |
| 18 | 50mcg ✓ | HF 2, Anxiety 3 | — | 6ч / 3 | Okay / 3 |
| 19 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 20 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 31 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 32 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 33 | 50mcg ✓ | HF 2, Anxiety 1 | Stress | 6ч / 3 | Okay / 3 |
| 34 | 50mcg ✓ | HF 2, Anxiety 3 | — | 6ч / 3 | Okay / 3 |
| 35 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 46 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 47 | 50mcg ✓ | HF 2, Anxiety 1 | Stress | 6ч / 3 | Okay / 3 |
| 48 | 50mcg ✓ | HF 2, Anxiety 3 | — | 6ч / 3 | Okay / 3 |
| 49 | 50mcg ✓ | HF 2, Anxiety 1 | Stress | 6ч / 3 | Okay / 3 |
| 50 | 50mcg ✓ | HF 2, Anxiety 3 | — | 6ч / 3 | Okay / 3 |
| 51 | 50mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 52 | 75mcg ✓ ← divider | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 59 | 75mcg ✓ | HF 2, Anxiety 1 | — | 6ч / 3 | Okay / 3 |
| 60 | 75mcg ✓ | HF 2, Anxiety 1 | Stress | 6ч / 3 | Okay / 3 |

**Итого залогировано: 26 из 60 календарных дней.** Смена дозы Estradiol — в День 52 → к Дню 60 прошло 8 из нужных 14 дней.

**Ожидаемый результат**

- Logged days = **26**; Passport должен показать «**4** дня осталось» (30−26), а не считать от 60 календарных дней
- HRT before/after: divider в День 52, gated с обратным отсчётом **\~6 дней** на День 60
- Stress→Anxiety: застряло на **6 парных событиях** → "6 из 7"
- Ключевая открытая проверка: как приложение трактует 34 пропущенных дня для HRT-адгеренции (missed dose по календарным дням vs исключение из расчёта)

---

## Сценарий 7 — 30 дней — Разнообразие симптомов + Coffee/Weather (Postmenopause, Progynova)

**Условия:** HRT — Progynova (таблетка) 1mg, ежедневно, без смены дозы.

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1 | Progynova 1mg ✓ | Fatigue 2 | — | 6.5ч / 3 | Okay / 3 |
| 2 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Headache 3 | Coffee | 6.5ч / 3 | Okay / 3 |
| 3 | Progynova 1mg ✓ | Fatigue 2, Skin dryness 1 | Weather | 6.5ч / 3 | Okay / 3 |
| 4 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Brain fog 3 | — | 6.5ч / 3 | Okay / 3 |
| 5 | Progynova 1mg ✓ | Fatigue 2, Low mood 1, Headache 3 | Coffee | 6.5ч / 3 | Low / 2 |
| 6 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Skin dryness 1 | Weather | 6.5ч / 3 | Okay / 3 |
| 7 | Progynova 1mg ✓ | Fatigue 2, Brain fog 3 | — | 6.5ч / 3 | Okay / 3 |
| 8 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Headache 3 | Coffee | 6.5ч / 3 | Okay / 3 |
| 9 | Progynova 1mg ✓ | Fatigue 2, Skin dryness 1 | Weather | 6.5ч / 3 | Okay / 3 |
| 10 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Low mood 1, Brain fog 3 | — | 6.5ч / 3 | Low / 2 |
| 11 | Progynova 1mg ✓ | Fatigue 2, Headache 3 | Coffee | 6.5ч / 3 | Okay / 3 |
| 12 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Skin dryness 1 | Weather | 6.5ч / 3 | Okay / 3 |
| 13 | Progynova 1mg ✓ | Fatigue 2, Brain fog 3 | — | 6.5ч / 3 | Okay / 3 |
| 14 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Headache 3 | Coffee | 6.5ч / 3 | Okay / 3 |
| 15 | Progynova 1mg ✓ | Fatigue 2, Skin dryness 1, Low mood 1 | Weather | 6.5ч / 3 | Low / 2 |
| 16 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Brain fog 3 | — | 6.5ч / 3 | Okay / 3 |
| 17 | Progynova 1mg ✓ | Fatigue 2, Headache 3 | Coffee | 6.5ч / 3 | Okay / 3 |
| 18 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Skin dryness 1 | Weather | 6.5ч / 3 | Okay / 3 |
| 19 | Progynova 1mg ✓ | Fatigue 2, Brain fog 3 | — | 6.5ч / 3 | Okay / 3 |
| 20 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Low mood 1, Headache 3 | Coffee | 6.5ч / 3 | Low / 2 |
| 21 | Progynova 1mg ✓ | Fatigue 2, Skin dryness 1 | Weather | 6.5ч / 3 | Okay / 3 |
| 22 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Brain fog 3 | — | 6.5ч / 3 | Okay / 3 |
| 23 | Progynova 1mg ✓ | Fatigue 2, Headache 3 | Coffee | 6.5ч / 3 | Okay / 3 |
| 24 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Skin dryness 1 | Weather | 6.5ч / 3 | Okay / 3 |
| 25 | Progynova 1mg ✓ | Fatigue 2, Low mood 1, Brain fog 3 | — | 6.5ч / 3 | Low / 2 |
| 26 | Progynova 1mg ✓ | Fatigue 2, Irritability 1 | — | 6.5ч / 3 | Okay / 3 |
| 27 | Progynova 1mg ✓ | Fatigue 2, Skin dryness 1 | Weather | 6.5ч / 3 | Okay / 3 |
| 28 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Brain fog 3 | — | 6.5ч / 3 | Okay / 3 |
| 29 | Progynova 1mg ✓ | Fatigue 2 | — | 6.5ч / 3 | Okay / 3 |
| 30 | Progynova 1mg ✓ | Fatigue 2, Irritability 1, Skin dryness 1 | — | 6.5ч / 3 | Okay / 3 |

**Ожидаемый результат**

- Most Frequent Symptoms: **Fatigue(30) > Irritability(15) > Skin dryness(10) > Brain fog(9) > Headache(8) > Low mood(5)**
- Coffee→Headache (same-day): 8 парных событий → карточка, без чипа
- Weather→Brain fog (next-day): 9 парных событий → карточка, без чипа
- Severity Trend по Fatigue: флэт → **"Stable"**
- Passport «Current HRT»: **Progynova 1mg**

---

## Сценарий 8 — 15 дней — Weekday-only vs Frequency change (два разных тира)

**Условия:** Utrogestan 100mg, twice weekly, изначально Пн/Чт.

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1 | 100mg ✓ | HF 2 | — | 6ч / 3 | Okay / 3 |
| 2 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 3 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 4 | 100mg ✓ | HF 2 | — | 6ч / 3 | Okay / 3 |
| 5 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 6 | — ← смена дней недели (Пн/Чт→Вт/Пт), НЕТ дивайдера | HF 2 | — | 6ч / 3 | Okay / 3 |
| 7 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 8 | 100mg ✓ | HF 2 | — | 6ч / 3 | Okay / 3 |
| 9 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 10 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 11 | 100mg ✓ | HF 2 | — | 6ч / 3 | Okay / 3 |
| 12 | — ← смена частоты twice-weekly→weekly, ЕСТЬ дивайдер | HF 2 | — | 6ч / 3 | Okay / 3 |
| 13 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 14 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 15 | 100mg ✓ | HF 2 | — | 6ч / 3 | Okay / 3 |

**Ожидаемый результат**

- День 6 (смена дней недели): **НЕТ дивайдера**, окно корреляции не сбрасывается
- День 12 (смена частоты): **ЕСТЬ дивайдер**, окно корреляции сбрасывается
- Если приложение путает эти тиры местами — нарушение правила про 3 тира изменений

---

## Сценарий 9 — 20 дней — Три уровня duplicate detection + правила удаления

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1 | Evorel patch 50mcg добавлен, weekly — активен | HF 2 | — | 6ч / 3 | Okay / 3 |
| 2 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 3 | Попытка добавить ДУБЛИКАТ Evorel 50mcg weekly → мягкое предупреждение | HF 2 | — | 6ч / 3 | Okay / 3 |
| 4 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 5 | Добавлен Evorel patch 75mcg weekly (др. параметры, 50mcg ещё активен) → НЕТ предупреждения | HF 2 | — | 6ч / 3 | Okay / 3 |
| 6 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 7 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 8 | Soft-stop Evorel 50mcg | HF 2 | — | 6ч / 3 | Okay / 3 |
| 9 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 10 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 11 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 12 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 13 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 14 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 15 | Повторно добавлен Evorel 50mcg weekly (resumed) → НЕТ предупреждения | HF 2 | — | 6ч / 3 | Okay / 3 |
| 16 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 17 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 18 | Попытка удалить Evorel 75mcg (есть история) → удаление БЛОКИРОВАНО | HF 2 | — | 6ч / 3 | Okay / 3 |
| 19 | — | HF 2 | — | 6ч / 3 | Okay / 3 |
| 20 | Добавлен Tibolone (0 истории) и сразу удалён → удаление РАЗРЕШЕНО | HF 2 | — | 6ч / 3 | Okay / 3 |

**Ожидаемый результат** — см. столбец «HRT» построчно выше: мягкое предупреждение на Дне 3, отсутствие предупреждения на Днях 5 и 15, блокировка удаления на Дне 18, разрешённое удаление на Дне 20.

---

## Сценарий 10 — 30 дней — PCOS Mode, нестандартный цикл

**Условия:** Стадия PCOS, HRT не настроен. Триггеров нет.

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1–5 | — (без HRT) | Anxiety 1, Brain fog 1, HF 1, Bleeding | — | 6.5ч / 3 | Okay / 3 |
| 6–30 | — (без HRT) | Anxiety 1, Brain fog 1, HF 1 | — | 6.5ч / 3 | Okay / 3 |

**Ожидаемый результат**

- Календарь показывает менструацию (Дни 1–5) и 25-дневный разрыв **без** предупреждения о "нетипичном"/"пропущенном" цикле
- Активный набор модулей — PCOS-конфигурация (specialist cycle + hormone sensitivity), не perimenopause
- HRT-модуль — не настроен, без ошибок

---

## Сценарий 11 — 60 дней — Gel + Ring, soft-stop/resume, слабая корреляция без чипа

**Условия:** Медикамент A — Estradiol gel, Дни 1–30 → soft-stop День 30 → resume День 45. Медикамент B — vaginal ring, весь период, независимо.

| День | HRT | Симптомы | Триггер | Sleep (длительность/качество 1–5) | Mood (категория/score 1–5) |
| --- | --- | --- | --- | --- | --- |
| 1 | Gel ✓ | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 2–3 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 4 | Gel ✓ | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 5–6 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 7 | Gel ✓ | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 8–9 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 10 | Gel ✓ | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 11–12 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 13 | Gel ✓ | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 14–15 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 16 | Gel ✓ | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 17–18 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 19 | Gel ✓ | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 20–21 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 22 | Gel ✓ | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 23–24 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 25 | Gel ✓ | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 26–27 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 28 | Gel ✓ | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 29–30 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 31 | — | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 32–33 | — | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 34 | — | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 35–36 | — | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 37 | — | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 38–39 | — | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 40 | — | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 41–42 | — | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 43 | — | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 44 | — | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 45 | Gel ✓ (resumed) | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 46 | Gel ✓ | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 47–48 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 49 | Gel ✓ | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 50–51 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 52 | Gel ✓ | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 53–54 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 55 | Gel ✓ | Ring ✓ | Irritability 3 | Coffee | 6ч / 3 |
| 56–57 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |
| 58 | Gel ✓ | Ring ✓ | Irritability 2 | Coffee | 6ч / 3 |
| 59–60 | Gel ✓ | Ring ✓ | Irritability 2 | — | 6ч / 3 |

**Ожидаемый результат**

- Gel: soft-stop/resume без предупреждения; Ring: отдельная карточка, форма "ring", своя адгеренция
- Coffee→Irritability: **≥14 парных событий** (20 всего), но эффект (2→3) проявляется лишь в половине случаев → % корреляции заметно ниже 70% → карточка отображается, **без** чипа и **без** негативного текста-заменителя

---

## Сводная таблица: что каждый сценарий проверяет

| Сценарий | Дней | Ключевая проверка |
| --- | --- | --- |
| 1 | 7 | Полный "пол" — везде недостаточно данных, corr. progress "3 из 7" |
| 2 | 15 | Before-окно физически недостижимо (permanent gate, не countdown) |
| 3 | 30 | Точная граница 14/14 дней для HRT before/after + moderate-корреляция на 9 событиях |
| 4 | 30 | Точная граница ровно 7 событий для корреляции, без HRT, нерегулярный цикл без warning |
| 5 | 60 | High-confidence чип (14 событий) + позитивная корреляция без чипа + worsening-тренд |
| 6 | 60 | Logged days ≠ calendar days на Passport, gated countdown в середине, застрявший триггер на 6/7 |
| 7 | 30 | Ранжирование Most Frequent Symptoms, два новых триггера (Coffee/Weather), другой препарат (Progynova) |
| 8 | 15 | Различие weekday-only и frequency-change тиров смены медикамента |
| 9 | 20 | Три уровня duplicate detection + правила удаления |
| 10 | 30 | Отдельная стадия PCOS, нестандартный цикл без ложного предупреждения |
| 11 | 60 | Формы gel/ring, soft-stop/resume, слабая корреляция ≥14 событий без чипа |