# SSRS Subscription CSV Guide

## CSV Format Overview

The CSV file for SSRS subscriptions requires specific columns in a particular order. Here's how to properly construct your CSV file:

## Required Columns

1. **ReportConfigId** - Unique GUID for the report configuration (format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
2. **ServerId** - Server identifier in format XXXXXX_YYYYY (6 alphanumeric + underscore + 5 numeric)
3. **ReportType** - Type of report or subfolder name (e.g., "Wellbeing", "Inspection")
4. **Description** - Human-readable description of the subscription
5. **EmailTo** - Email recipient(s)
6. **EmailCC** - Carbon copy recipients (can be empty)
7. **EmailReplyTo** - Reply-to email address
8. **RenderFormat** - Format for the report (PDF, EXCELOPENXML, WORDOPENXML)
9. **EmailSubject** - Subject line for the email
10. **IncludeReport** - Whether to include the report in the email (true/false)
11. **EmailPriority** - Priority of the email (NORMAL, HIGH, LOW)
12. **ScheduleType** - Type of schedule (Daily, Weekly)
13. **ScheduleTime** - Time to send report (format: HH:MM)
14. **ScheduleDaysOfWeek** - Days to send for Weekly schedules (semicolon-separated)
15. **ScheduleDayOfMonth** - Not used (leave empty)
16. **ScheduleInterval** - Frequency interval (1 = every occurrence, 2 = every other, etc.)

## Schedule Types

### Daily Schedule
- Set **ScheduleType** to "Daily"
- Leave **ScheduleDaysOfWeek** empty
- Set **ScheduleInterval** to determine frequency (1=daily, 2=every other day)

### Weekly Schedule
- Set **ScheduleType** to "Weekly"
- Specify days using **ScheduleDaysOfWeek** with semicolons between days
- Valid days: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
- Set **ScheduleInterval** for frequency (1=weekly, 2=biweekly, 4=monthly, 12=quarterly)

## Common Patterns

1. **Daily Report**: 
   - ScheduleType: "Daily"
   - ScheduleInterval: "1"
   - ScheduleDaysOfWeek: (empty)

2. **Specific Days Weekly Report**: 
   - ScheduleType: "Weekly"
   - ScheduleDaysOfWeek: "Monday;Wednesday;Friday"
   - ScheduleInterval: "1"

3. **Monthly Report** (using Weekly with 4-week interval):
   - ScheduleType: "Weekly"
   - ScheduleDaysOfWeek: "Monday"
   - ScheduleInterval: "4"

4. **Quarterly Report** (using Weekly with 12-week interval):
   - ScheduleType: "Weekly"
   - ScheduleDaysOfWeek: "Monday"
   - ScheduleInterval: "12"

5. **Every Day of the Week**:
   - ScheduleType: "Weekly"
   - ScheduleDaysOfWeek: "Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday"
   - ScheduleInterval: "1"

## Report Formats

- **PDF**: Standard PDF format
- **EXCELOPENXML**: Excel format
- **WORDOPENXML**: Word format

## Email Priority

- **NORMAL**: Standard priority
- **HIGH**: High priority
- **LOW**: Low priority

## Example CSV Rows

```
055beca7-9b96-4c53-b58f-48afb8ee6109,TKS017_26790,Wellbeing,Daily WellBeing Report,user1@company.com,manager@company.com,noreply@company.com,PDF,Daily WellBeing Report,true,NORMAL,Daily,08:00,,,1
16fde438-2b4e-4a67-9f3d-c853dd73771c,TKS017_26790,Wellbeing,Monthly Sales Report,sales@company.com,finance@company.com,noreply@company.com,EXCELOPENXML,Monthly Sales Report,true,HIGH,Weekly,07:00,Monday,,4
a7c91234-5678-4def-b987-123456789abc,TKS017_26790,Wellbeing,Weekly Status,inventory@company.com,,noreply@company.com,PDF,Weekly Report,true,NORMAL,Weekly,09:00,Monday;Wednesday;Friday,,1
```

## Important Notes

1. Do not include spaces after semicolons in the ScheduleDaysOfWeek field
2. Ensure the ServerId follows the correct pattern
3. For nested folder paths, use an underscore instead of a forward slash
4. The ReportConfigId must be a valid GUID format
5. All boolean values should be "true" or "false" (lowercase)

When creating in Excel, save as CSV (Comma delimited) format to ensure proper formatting for import.