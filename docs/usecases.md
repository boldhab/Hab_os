# HabOS — Complete Use Case Specifications

## Overview

HabOS is a personal life operating system that integrates productivity, development, learning, fitness, finance, and personal growth into a single connected platform. This document defines all 182 use cases organized into 24 modules, with detailed descriptions, relationships, and specifications.

---

## Module 1: Authentication & Account Management (UC-01 to UC-05)

### UC-01 — Register Account

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-01 |
| **Name** | Register Account |
| **Actor** | New User |
| **Priority** | High |
| **Frequency** | Once per user |

**Purpose:** Enable a new user to create a HabOS account to access the system.

**Preconditions:**
- User does not already have an account
- User has a valid email address
- Internet connection is available

**Main Flow:**
1. User navigates to the registration page
2. User enters full name, email address, and password
3. User confirms password
4. System validates email format and password strength
5. System checks if email is already registered
6. System hashes password using bcrypt
7. System creates user account with default settings
8. System creates default categories and preferences
9. System redirects to dashboard with welcome message

**Alternative Flows:**
- **A1: Email already exists** → System displays error and prompts for login or password reset
- **A2: Invalid password** → System requires minimum 8 characters with mix of letters, numbers, and symbols
- **A3: Missing required fields** → System highlights incomplete fields
- **A4: Network error** → System saves registration attempt and retries

**Postconditions:**
- New user account is created
- User is authenticated
- Default configuration is initialized

---

### UC-02 — Login

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-02 |
| **Name** | Login |
| **Actor** | Registered User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Authenticate a registered user and establish a session.

**Preconditions:**
- User has a registered account
- Account is active

**Main Flow:**
1. User navigates to login page
2. User enters email and password
3. System validates credentials against stored hash
4. System generates JWT access token (15 min expiry)
5. System generates refresh token (30 day expiry)
6. System stores refresh token in database
7. System returns tokens to client
8. Client stores tokens securely
9. System redirects to dashboard

**Alternative Flows:**
- **A1: Incorrect credentials** → System displays "Invalid email or password" error
- **A2: Account locked** → System displays lock message after multiple failures
- **A3: Account not verified** → System prompts for verification
- **A4: Network error** → System displays connection error

**Postconditions:**
- User is authenticated
- Active session is established
- Tokens are stored securely

---

### UC-03 — Logout

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-03 |
| **Name** | Logout |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Daily |

**Purpose:** End the user's current session and invalidate authentication tokens.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects logout option
2. System invalidates refresh token in database
3. System clears local token storage
4. System redirects to login page

**Alternative Flows:**
- **A1: Token already expired** → System clears local storage and redirects to login
- **A2: Network error during invalidation** → System still clears local tokens

**Postconditions:**
- User is no longer authenticated
- Tokens are invalidated
- Session is terminated

---

### UC-04 — Manage Profile

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-04 |
| **Name** | Manage Profile |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly/Monthly |

**Purpose:** Allow users to view and update their personal information and preferences.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to profile settings
2. System displays current profile information:
   - Name
   - Email
   - Avatar/photo
   - Time zone
   - Date format preference
3. User modifies desired fields
4. User saves changes
5. System validates updates
6. System stores changes
7. System displays success confirmation

**Alternative Flows:**
- **A1: Invalid email format** → System displays error and requests correction
- **A2: Email already in use** → System displays conflict error
- **A3: Password change requested** → System requires current password verification

**Postconditions:**
- User profile is updated
- Changes are persisted

---

### UC-05 — Configure Notifications

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-05 |
| **Name** | Configure Notifications |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly/As Needed |

**Purpose:** Allow users to control which notifications they receive and how they are delivered.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to notification settings
2. System displays notification categories:
   - Task reminders
   - Exam reminders
   - Goal reminders
   - Habit reminders
   - Workout reminders
   - Budget alerts
   - Streak notifications
   - Scheduled event reminders
3. User toggles notifications on/off
4. User sets timing preferences (e.g., 30 min before, 1 hour before)
5. User sets delivery method (push, email, both)
6. User saves preferences
7. System stores configuration

**Alternative Flows:**
- **A1: Disabled notifications** → System shows warning about missing important events
- **A2: No delivery method selected** → System requires at least one method

**Postconditions:**
- Notification preferences are saved
- Future notifications respect user preferences

---

## Module 2: Dashboard (UC-06 to UC-09)

### UC-06 — View Today's Dashboard

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-06 |
| **Name** | View Today's Dashboard |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily (every session) |

**Purpose:** Provide a comprehensive, single-screen overview of today's activities, tasks, and progress across all modules.

**Preconditions:**
- User is authenticated
- Data exists in various modules

**Main Flow:**
1. User opens HabOS or navigates to dashboard
2. System identifies current date and time
3. System retrieves data from all active modules:
   - Tasks (today's due, overdue, upcoming)
   - Schedule (today's events)
   - Goals (active goals status)
   - Habits (today's completion status)
   - Focus (today's total focus time)
   - Coding (today's commits, PRs, time)
   - Study (today's study sessions)
   - Gym (today's workout status)
   - Finance (today's transactions, budget status)
   - Streaks (active streak status)
4. System calculates summary statistics
5. System prioritizes and organizes information
6. System displays dashboard

**Dashboard Layout:**
```
┌─────────────────────────────────┐
│ 🔆 GOOD MORNING, [USER]        │
│                                  │
│ TODAY'S PRIORITIES               │
│ ☐ Complete authentication API   │
│ ☐ Study for Advanced Java exam  │
│ ☐ Gym - Chest & Triceps         │
│                                  │
│ TODAY'S STATS                    │
│ Focus: 2h 35m  ─┐                │
│ Coding: 1h 45m  │                │
│ Study: 50m      ├─ Progress bar  │
│ Gym: ✅         ─┘                │
│                                  │
│ 🔥 Coding streak: 18 days       │
│ ┌────────┐  ┌────────┐          │
│ │ Tasks   │  │ Focus   │          │
│ │ 7/10    │  │ 2.5h    │          │
│ └────────┘  └────────┘          │
│ ┌────────┐  ┌────────┐          │
│ │ Coding  │  │ Study   │          │
│ │ 1.8h    │  │ 50m     │          │
│ └────────┘  └────────┘          │
└─────────────────────────────────┘
```

**Alternative Flows:**
- **A1: No data for today** → System shows empty state with "Start adding tasks and activities!" message
- **A2: Overdue tasks exist** → System highlights them in red with priority indicator

**Postconditions:**
- User sees current day's overview
- Dashboard updates in real-time as data changes

---

### UC-07 — View Daily Summary

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-07 |
| **Name** | View Daily Summary |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Show a detailed breakdown of today's activities and progress.

**Preconditions:**
- User is authenticated
- Data exists for today

**Main Flow:**
1. User accesses daily summary view
2. System compiles daily statistics:
   - Tasks: completed/total, overdue count
   - Coding: hours, commits, projects touched
   - Study: hours, courses covered
   - Gym: workout completed, exercises done
   - Expenses: total spent, budget status
   - Habits: completed/missed
3. System calculates daily completion rate
4. System displays summary with visual indicators

**Alternative Flows:**
- **A1: Incomplete data** → System shows what's completed vs. pending
- **A2: End of day summary** → System displays "Day Review" option

**Postconditions:**
- User understands daily performance
- Insights are available for reflection

---

### UC-08 — View Progress Overview

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-08 |
| **Name** | View Progress Overview |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Show progress across all major life areas with visual indicators.

**Preconditions:**
- User is authenticated
- Data exists across multiple modules

**Main Flow:**
1. User navigates to progress view
2. System calculates progress for each area:
   - Coding: project completion, learning progress
   - Study: course completion, grades
   - Gym: strength progress, consistency
   - Goals: milestone completion
   - Habits: consistency rate
   - Finance: savings rate, budget adherence
3. System displays progress bars
4. System shows trend indicators (↑, ↓, →)

**Visual Representation:**
```
PROGRESS OVERVIEW
═══════════════════
Coding     ████████░░ 80%
Study      ██████░░░░ 70%
Gym        █████████░ 90%
Goals      ██████░░░░ 65%
Habits     ████████░░ 85%
Finance    ███████░░░ 75%

• Coding: +5% this week
• Study: -2% this week
• Gym: Maintaining
```

**Postconditions:**
- User sees holistic progress
- Areas needing attention are identified

---

### UC-09 — View Life Score

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-09 |
| **Name** | View Life Score |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Daily/Weekly |

**Purpose:** Provide a high-level indicator of consistency and balance across life areas.

**Preconditions:**
- User is authenticated
- Data exists in at least one module

**Main Flow:**
1. User navigates to Life Score view
2. System calculates weighted score from active areas:
   - Tasks completion rate
   - Coding consistency
   - Study consistency
   - Gym consistency
   - Goal progress
   - Habit completion
   - Financial health
3. System normalizes scores (0-100)
4. System applies configurable weights
5. System calculates composite score
6. System displays score with breakdown

**Score Calculation:**
```
Life Score = Σ(Area Score × Weight) / Σ(Weights)

Example:
Coding: 80 × 20% = 16
Study: 70 × 20% = 14
Gym: 90 × 15% = 13.5
Goals: 60 × 15% = 9
Habits: 85 × 10% = 8.5
Finance: 80 × 10% = 8
Tasks: 75 × 10% = 7.5
───────────────
Total: 76.5
```

**Alternative Flows:**
- **A1: Some areas inactive** → System adjusts weights proportionally
- **A2: Score drops significantly** → System highlights declined areas

**Postconditions:**
- User sees consistency score
- Score changes tracked over time

**Important Note:** The Life Score represents **consistency and balance**, not personal worth. It's a tool for self-reflection, not evaluation.

---

## Module 3: Task Management (UC-10 to UC-17)

### UC-10 — Create Task

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-10 |
| **Name** | Create Task |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily (multiple times) |

**Purpose:** Add a specific action item that needs to be accomplished.

**Preconditions:**
- User is authenticated
- User has a goal or project to work toward (optional)

**Main Flow:**
1. User selects "Create Task" (from dashboard, task list, or quick-add)
2. User enters required fields:
   - Title (required)
   - Description (optional)
   - Priority: Low/Medium/High/Critical
   - Due date (optional)
   - Estimated minutes (optional)
   - Project association (optional)
   - Goal association (optional)
   - Category/tag (optional)
3. System validates input
4. System checks for duplicate/conflicting tasks
5. System creates task with "todo" status
6. System saves task to database
7. System adds task to today's list if due today or overdue
8. System updates project progress if linked to project
9. System updates goal progress if linked to goal

**Alternative Flows:**
- **A1: Missing title** → System displays "Title is required" error
- **A2: Due date in past** → System warns about overdue task
- **A3: Quick-add from dashboard** → System uses minimal fields (title only)

**Postconditions:**
- Task is created and stored
- Task appears in relevant lists
- Related projects/goals are updated

---

### UC-11 — Edit Task

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-11 |
| **Name** | Edit Task |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Several times daily |

**Purpose:** Modify an existing task's details.

**Preconditions:**
- Task exists
- User has permission to edit (own task)

**Main Flow:**
1. User selects a task from any list
2. User opens task detail view
3. User taps edit icon
4. System displays current values in editable form
5. User modifies any fields
6. System validates changes
7. System saves updates
8. System refreshes affected views
9. System recalculates linked project/goal progress

**Alternative Flows:**
- **A1: Project changed** → System updates progress for old and new projects
- **A2: Due date changed** → System adjusts task position in lists

**Postconditions:**
- Task is updated
- Changes reflected across system
- Related progress recalculated

---

### UC-12 — Delete Task

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-12 |
| **Name** | Delete Task |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Occasionally |

**Purpose:** Remove a task that is no longer needed or was created by mistake.

**Preconditions:**
- Task exists
- User owns the task

**Main Flow:**
1. User selects task from any list
2. User opens task detail view
3. User selects delete option
4. System displays confirmation dialog
5. User confirms deletion
6. System removes task from database (or archives)
7. System updates relevant lists
8. System recalculates project/goal progress if linked

**Alternative Flows:**
- **A1: Task has time entries** → System asks if time entries should be deleted or preserved
- **A2: Task is part of active project** → System warns about removing task

**Postconditions:**
- Task is removed
- Related views are refreshed
- Project/goal progress is recalculated

---

### UC-13 — Complete Task

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-13 |
| **Name** | Complete Task |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Multiple times daily |

**Purpose:** Mark a task as completed and trigger downstream updates.

**Preconditions:**
- Task exists
- Task is not already completed

**Main Flow:**
1. User selects task completion action (checkbox, swipe, button)
2. System changes status from `todo` to `completed`
3. System records completion timestamp
4. System updates dashboard statistics:
   - Task completion count increases
   - Task completion rate recalculates
5. System updates project progress if linked
6. System updates goal progress if linked
7. System updates relevant streaks
8. System triggers success haptic/visual feedback
9. System removes task from "Today's tasks" if applicable

**Alternative Flows:**
- **A1: Task overdue** → System records completion but marks as "completed late"
- **A2: Task with dependencies** → System checks dependencies first
- **A3: Undo completion** → User can undo within 5 seconds

**Postconditions:**
- Task status is `completed`
- Dashboard stats are updated
- Project/goal progress reflects completion
- Streak updates if applicable

**Relationships:**
- **Includes:** Update Dashboard (UC-06)
- **Includes:** Update Analytics (UC-144, UC-145)
- **Includes:** Update Streaks (UC-28)

---

### UC-14 — Set Task Priority

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-14 |
| **Name** | Set Task Priority |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | During task creation/editing |

**Purpose:** Assign priority level to tasks to help with planning and focus.

**Preconditions:**
- Task exists

**Main Flow:**
1. User selects priority option
2. System provides priority levels:
   - **Critical** (🔴): Must do today, highest impact
   - **High** (🟠): Important, do soon
   - **Medium** (🟡): Normal priority
   - **Low** (🟢): Can wait if needed
3. User selects priority
4. System saves priority
5. System updates task display with color indicator
6. System adjusts task position in sorted lists

**Postconditions:**
- Task has assigned priority
- Task appears in appropriate priority sections

---

### UC-15 — View Tasks

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-15 |
| **Name** | View Tasks |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Multiple times daily |

**Purpose:** Display tasks in various organizational views.

**Preconditions:**
- User is authenticated
- Tasks exist

**Main Flow:**
1. User navigates to task view
2. System displays tasks organized by view:
   - **Today's Tasks**: Due today + overdue + unassigned
   - **Upcoming Tasks**: Due in future
   - **Completed Tasks**: Done today/this week
   - **Overdue Tasks**: Missed deadlines
   - **All Tasks**: Complete list with filters
3. System shows task details:
   - Title
   - Priority indicator
   - Due date (if set)
   - Project association (if any)
   - Status
   - Quick-complete checkbox

**Alternative Flows:**
- **A1: No tasks** → Display empty state with "Create your first task" button
- **A2: Many tasks** → Implement pagination or infinite scroll

**Postconditions:**
- User sees task list
- Tasks are organized appropriately

---

### UC-16 — Filter Tasks

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-16 |
| **Name** | Filter Tasks |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Several times daily |

**Purpose:** Narrow task list to specific criteria for focused viewing.

**Preconditions:**
- User is in task view
- Multiple tasks exist

**Main Flow:**
1. User selects filter option
2. System presents filter criteria:
   - **Status**: All/Todo/In Progress/Completed/Blocked
   - **Priority**: All/Low/Medium/High/Critical
   - **Date**: Today/This week/Overdue/All
   - **Project**: All/Select specific projects
   - **Category**: All/Select specific categories
   - **Goal**: All/Select specific goals
3. User selects filter criteria
4. System applies filters and updates list
5. System shows active filter badges

**Alternative Flows:**
- **A1: No results** → Display "No tasks match filters" message
- **A2: Multiple filters** → System shows combined results

**Postconditions:**
- Task list is filtered
- Filter state is remembered for session

---

### UC-17 — Receive Task Reminder

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-17 |
| **Name** | Receive Task Reminder |
| **Actor** | User, Notification Service |
| **Priority** | Medium |
| **Frequency** | As scheduled |

**Purpose:** Notify user about upcoming or overdue tasks.

**Preconditions:**
- Task has due date
- Notification is enabled
- User is authenticated (device registered)

**Main Flow:**
1. Notification service checks tasks with due dates
2. System determines tasks requiring reminders:
   - Tasks due today (morning reminder)
   - Tasks due tomorrow (evening reminder)
   - Overdue tasks (daily reminder)
   - Tasks approaching within user's reminder window
3. System creates notification with task details
4. System sends push notification or email
5. User can tap notification to open task

**Alternative Flows:**
- **A1: Task completed before reminder** → System cancels scheduled reminder
- **A2: User disables reminders** → No notifications sent

**Postconditions:**
- User receives notification
- User can act on reminder

---

## Module 4: Schedule (UC-18 to UC-23)

### UC-18 — Create Schedule Event

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-18 |
| **Name** | Create Schedule Event |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Plan and record time-blocked activities.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Add Event" on calendar/schedule view
2. User enters event details:
   - Title (required)
   - Date (required)
   - Start time (required)
   - End time (required)
   - Description (optional)
   - Location (optional)
   - Color/type (optional)
   - Recurring pattern (optional)
3. System validates:
   - Start time before end time
   - No conflicting events
4. System saves event
5. System displays on calendar
6. System adds to daily schedule

**Alternative Flows:**
- **A1: Time conflict** → System warns and shows overlapping event
- **A2: Recurring event** → System asks about single or recurring pattern

**Postconditions:**
- Event is scheduled
- Calendar is updated

---

### UC-19 — Edit Schedule Event

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-19 |
| **Name** | Edit Schedule Event |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Modify existing scheduled events.

**Preconditions:**
- Event exists

**Main Flow:**
1. User selects event on calendar
2. User chooses edit option
3. System displays event details
4. User modifies time, date, title, or description
5. System validates changes
6. System saves updates
7. System refreshes calendar

**Postconditions:**
- Event is updated
- Calendar reflects changes

---

### UC-20 — Delete Schedule Event

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-20 |
| **Name** | Delete Schedule Event |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Occasionally |

**Purpose:** Remove an event from the schedule.

**Preconditions:**
- Event exists

**Main Flow:**
1. User selects event on calendar
2. User selects delete option
3. System asks for confirmation
4. User confirms
5. System removes event
6. System updates calendar

**Postconditions:**
- Event is removed
- Calendar is updated

---

### UC-21 — View Daily Schedule

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-21 |
| **Name** | View Daily Schedule |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Display today's time-blocked activities in chronological order.

**Preconditions:**
- User is authenticated
- Events exist for today

**Main Flow:**
1. User navigates to daily schedule
2. System retrieves today's events
3. System orders events by time
4. System displays timeline view:
```
07:00 ─ Wake up
08:00 ─ University - Advanced Database
10:00 ─ Focus Session - Backend API
13:00 ─ Lunch
14:00 ─ Study - Java
18:00 ─ Gym
```
5. System shows current time indicator
6. System highlights upcoming events

**Alternative Flows:**
- **A1: No events** → Display "Nothing scheduled today" message
- **A2: Overlapping events** → Display conflict warning

**Postconditions:**
- User sees daily schedule
- Time-block visualization is shown

---

### UC-22 — View Weekly Schedule

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-22 |
| **Name** | View Weekly Schedule |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** View scheduled activities across the entire week.

**Preconditions:**
- User is authenticated
- Events exist for the week

**Main Flow:**
1. User navigates to weekly schedule
2. System displays 7-day calendar view
3. System shows events on each day
4. System highlights current day
5. User can scroll through weeks
6. System shows week number and date range

**Postconditions:**
- User sees weekly overview
- Planning view is available

---

### UC-23 — Receive Schedule Reminder

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-23 |
| **Name** | Receive Schedule Reminder |
| **Actor** | User, Notification Service |
| **Priority** | Medium |
| **Frequency** | As scheduled |

**Purpose:** Notify user about upcoming scheduled events.

**Preconditions:**
- Event exists
- Notification is enabled

**Main Flow:**
1. System checks upcoming events
2. System identifies events starting within reminder window
3. System sends notification with event details
4. User can tap to view event

**Postconditions:**
- User receives reminder
- User is prepared for upcoming event

---

## Module 5: Habits & Streaks (UC-24 to UC-30)

### UC-24 — Create Habit

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-24 |
| **Name** | Create Habit |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Monthly |

**Purpose:** Establish a new routine or behavior to track.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Add Habit"
2. User enters habit details:
   - Name (required)
   - Description (optional)
   - Frequency: Daily/Weekly/Specific days
   - Target: Duration/Count/Checkbox
   - Category (optional)
   - Reminder time (optional)
   - Start date
3. System validates input
4. System creates habit tracking
5. System sets up daily/weekly entries
6. System adds to habit list

**Alternative Flows:**
- **A1: Habit already exists** → System prompts to reactivate or update

**Postconditions:**
- Habit is created
- Tracking begins on start date

---

### UC-25 — Edit Habit

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-25 |
| **Name** | Edit Habit |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Modify an existing habit's details.

**Preconditions:**
- Habit exists

**Main Flow:**
1. User selects habit from list
2. User chooses edit option
3. System displays current details
4. User modifies name, frequency, target, or reminder
5. System validates changes
6. System saves updates
7. System refreshes habit list

**Postconditions:**
- Habit is updated
- Future tracking uses new parameters

---

### UC-26 — Delete Habit

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-26 |
| **Name** | Delete Habit |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Occasionally |

**Purpose:** Remove a habit from tracking.

**Preconditions:**
- Habit exists

**Main Flow:**
1. User selects habit
2. User chooses delete option
3. System asks for confirmation
4. User confirms
5. System archives or removes habit
6. System preserves history but stops tracking

**Postconditions:**
- Habit is inactive
- History is preserved

---

### UC-27 — Mark Habit Complete

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-27 |
| **Name** | Mark Habit Complete |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily (multiple times) |

**Purpose:** Record successful completion of a habit.

**Preconditions:**
- Habit exists
- Today's date is within tracking period

**Main Flow:**
1. User selects habit from dashboard or habit list
2. User taps complete button
3. System records completion with timestamp
4. System updates:
   - Current streak count
   - Completion rate
   - Longest streak (if applicable)
   - Dashboard statistics
5. System provides positive feedback

**Alternative Flows:**
- **A1: Habit already completed** → System shows completion status
- **A2: Missed habit** → System allows logging with note

**Postconditions:**
- Habit marked completed for today
- Streak updates
- Analytics refresh

---

### UC-28 — Track Habit Streak

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-28 |
| **Name** | Track Habit Streak |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Calculate consecutive completion counts for habits.

**Preconditions:**
- Habit tracking exists

**Main Flow:**
1. System records daily habit completion
2. System checks for consecutive days (Daily) or occurrences (Weekly)
3. System calculates:
   - Current streak: consecutive days completed
   - Longest streak: maximum consecutive days ever
   - Completion rate: completed days / total tracked days
4. System stores streak data
5. System displays streak on dashboard and habit view

**Postconditions:**
- Streak data is current
- User sees motivation metrics

---

### UC-29 — View Habit History

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-29 |
| **Name** | View Habit History |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** See historical completion data for habits.

**Preconditions:**
- Habit exists
- History exists

**Main Flow:**
1. User selects habit
2. User navigates to history view
3. System displays:
   - Calendar view with completion markers
   - List view with dates and notes
   - Statistics: streaks, consistency
   - Trends over time

**Postconditions:**
- User sees habit history
- Patterns can be identified

---

### UC-30 — Receive Habit Reminder

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-30 |
| **Name** | Receive Habit Reminder |
| **Actor** | User, Notification Service |
| **Priority** | Medium |
| **Frequency** | As scheduled |

**Purpose:** Remind user to complete habits.

**Preconditions:**
- Habit exists
- Habit has reminder set
- Habit not yet completed today

**Main Flow:**
1. System checks habits not completed
2. System identifies reminders due
3. System sends notification
4. User can tap to mark habit complete

**Postconditions:**
- User receives reminder
- User can act on reminder

---

## Module 6: Focus (UC-31 to UC-37)

### UC-31 — Start Focus Session

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-31 |
| **Name** | Start Focus Session |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily (multiple times) |

**Purpose:** Begin a timed concentration session for productive work.

**Preconditions:**
- User is authenticated
- No active focus session running

**Main Flow:**
1. User selects "Start Focus" from dashboard or focus view
2. System presents focus options:
   - **Pomodoro**: 25 minutes
   - **Deep Work**: 50 minutes
   - **Extended**: 90 minutes
   - **Custom**: Set custom duration
   - **Unlimited**: No timer, just track
3. User selects duration
4. User optionally selects category:
   - Coding
   - Study
   - Project
   - Reading
   - Other
5. User optionally adds task association
6. System starts timer with visual countdown
7. System shows focus in progress state
8. System may display motivational quote or start sound

**Alternative Flows:**
- **A1: Custom duration** → User enters minutes/hours
- **A2: Task associated** → System links focus to task

**Postconditions:**
- Focus session is active
- Timer is running
- System is tracking focused time

---

### UC-32 — Pause Focus Session

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-32 |
| **Name** | Pause Focus Session |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | During sessions |

**Purpose:** Temporarily stop the focus timer during interruptions.

**Preconditions:**
- Focus session is active

**Main Flow:**
1. User selects pause button
2. System stops the timer
3. System records pause timestamp
4. System shows paused state with elapsed time
5. System allows user to resume or end session

**Postconditions:**
- Timer is paused
- Session time is preserved

---

### UC-33 — Resume Focus Session

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-33 |
| **Name** | Resume Focus Session |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | During sessions |

**Purpose:** Continue a paused focus session.

**Preconditions:**
- Focus session is paused

**Main Flow:**
1. User selects resume button
2. System restarts the timer from where it paused
3. System records resume timestamp
4. Session continues

**Postconditions:**
- Timer resumes
- Total time accumulates

---

### UC-34 — End Focus Session

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-34 |
| **Name** | End Focus Session |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | End of sessions |

**Purpose:** Conclude a focus session and record the duration.

**Preconditions:**
- Focus session is active or paused

**Main Flow:**
1. User selects end session
2. System stops timer
3. System calculates total duration
4. System saves session record:
   - Duration
   - Category
   - Task association (if any)
   - Notes (optional)
5. System updates:
   - Dashboard focus stats
   - Analytics
   - Task time tracking (if associated)
6. System displays session summary

**Alternative Flows:**
- **A1: Session less than 5 minutes** → System may prompt "Was this really a focus session?"
- **A2: Session exceeds target** → System celebrates "You crushed it!"

**Postconditions:**
- Focus session is recorded
- Analytics are updated
- Task time is updated if associated

---

### UC-35 — Categorize Focus Session

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-35 |
| **Name** | Categorize Focus Session |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | During session setup or after |

**Purpose:** Tag focus sessions for better analytics.

**Preconditions:**
- Focus session exists

**Main Flow:**
1. System presents category options:
   - Coding
   - Study
   - Project
   - Reading
   - Other
2. User selects category (can be changed during/after)
3. System saves category
4. System uses category for analytics

**Postconditions:**
- Session has category
- Analytics are categorized

---

### UC-36 — View Focus History

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-36 |
| **Name** | View Focus History |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** View past focus sessions and patterns.

**Preconditions:**
- Focus history exists

**Main Flow:**
1. User navigates to focus history
2. System displays sessions organized by:
   - Today
   - This week
   - This month
   - Custom range
3. System shows for each session:
   - Date
   - Duration
   - Category
   - Task (if associated)
   - Notes
4. System shows summary statistics:
   - Total focus time
   - Average session length
   - Category breakdown

**Postconditions:**
- User sees focus history
- Patterns are visible

---

### UC-37 — Calculate Focus Time

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-37 |
| **Name** | Calculate Focus Time |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Aggregate focus time across periods for insights.

**Preconditions:**
- Focus sessions exist

**Main Flow:**
1. System queries focus sessions
2. System calculates:
   - Today: total minutes
   - This week: total minutes
   - This month: total minutes
   - Category breakdown: time per category
   - Average per day
   - Total sessions
3. System stores aggregates for quick display
4. System updates dashboard and analytics

**Postconditions:**
- Focus statistics are available
- Dashboards reflect current data

---

## Module 7: Developer Hub - Projects (UC-38 to UC-42)

### UC-38 — Create Project

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-38 |
| **Name** | Create Project |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Monthly |

**Purpose:** Create a software project to manage features, bugs, and progress.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "New Project"
2. User enters project details:
   - Name (required)
   - Description (optional)
   - Repository URL (optional)
   - Status: Planning/In Progress/Completed/Archived
   - Technologies (optional)
3. System validates input
4. System creates project
5. System sets up project structure
6. System adds to project list

**Postconditions:**
- Project is created
- Ready for features and tasks

---

### UC-39 — Edit Project

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-39 |
| **Name** | Edit Project |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Modify project details.

**Preconditions:**
- Project exists

**Main Flow:**
1. User selects project
2. User chooses edit option
3. System displays project details
4. User modifies name, description, status, or technologies
5. System validates changes
6. System saves updates

**Postconditions:**
- Project is updated

---

### UC-40 — Delete Project

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-40 |
| **Name** | Delete Project |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Rarely |

**Purpose:** Remove or archive a project.

**Preconditions:**
- Project exists

**Main Flow:**
1. User selects project
2. User selects delete option
3. System asks for confirmation
4. System warns about associated tasks, features, and bugs
5. User confirms
6. System archives project
7. System unlinks tasks (does not delete them)

**Postconditions:**
- Project is archived/deleted
- Tasks are unlinked but preserved

---

### UC-41 — View Project

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-41 |
| **Name** | View Project |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Display project details, progress, and components.

**Preconditions:**
- Project exists

**Main Flow:**
1. User selects project from list
2. System displays project details:
   - Name and description
   - Progress percentage
   - Status
   - Technologies
   - Feature list with statuses
   - Bug list with priorities
   - Recent commits (if GitHub integrated)
3. System shows progress bar
4. System shows task completion metrics

**Postconditions:**
- User sees project overview
- Progress is visible

---

### UC-42 — Update Project Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-42 |
| **Name** | Update Project Progress |
| **Actor** | Authenticated User (Manual) / System (Automatic) |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Calculate or manually update project completion progress.

**Preconditions:**
- Project exists
- Features or tasks exist

**Main Flow:**
1. System calculates progress from features:
   ```
   Progress = (Completed Features / Total Features) × 100%
   ```
2. System can also calculate from tasks:
   ```
   Progress = (Completed Tasks / Total Tasks) × 100%
   ```
3. System updates progress bar
4. System displays percentage
5. User can manually adjust if needed

**Alternative Flows:**
- **A1: No features/tasks** → Show 0% progress
- **A2: Manual override** → User sets custom percentage

**Postconditions:**
- Progress is updated
- Dashboard reflects current progress

---

## Module 8: Developer Hub - Features (UC-43 to UC-47)

### UC-43 — Create Feature

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-43 |
| **Name** | Create Feature |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Add a new feature to a project.

**Preconditions:**
- Project exists
- User is authenticated

**Main Flow:**
1. User navigates to project
2. User selects "Add Feature"
3. User enters feature details:
   - Name (required)
   - Description (optional)
   - Status: TODO/In Progress/Completed
   - Priority: Low/Medium/High/Critical
   - Assigned task (optional)
4. System validates input
5. System creates feature
6. System updates project progress

**Postconditions:**
- Feature is created
- Project progress recalculated

---

### UC-44 — Edit Feature

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-44 |
| **Name** | Edit Feature |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Modify existing feature details.

**Preconditions:**
- Feature exists

**Main Flow:**
1. User selects feature
2. User chooses edit option
3. System displays feature details
4. User modifies name, description, status, or priority
5. System validates changes
6. System saves updates
7. System updates project progress

**Postconditions:**
- Feature is updated
- Project progress recalculated

---

### UC-45 — Delete Feature

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-45 |
| **Name** | Delete Feature |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Occasionally |

**Purpose:** Remove a feature from the project.

**Preconditions:**
- Feature exists

**Main Flow:**
1. User selects feature
2. User selects delete
3. System asks for confirmation
4. User confirms
5. System removes feature
6. System updates project progress

**Postconditions:**
- Feature is removed
- Project progress recalculated

---

### UC-46 — Update Feature Status

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-46 |
| **Name** | Update Feature Status |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Track feature development progress.

**Preconditions:**
- Feature exists

**Main Flow:**
1. User selects feature
2. System presents status options:
   - TODO
   - In Progress
   - Completed
   - Blocked
3. User selects status
4. System updates feature
5. System recalculates project progress
6. System updates dashboard

**Postconditions:**
- Feature status updated
- Project progress recalculated

---

### UC-47 — Track Feature Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-47 |
| **Name** | Track Feature Progress |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Calculate project completion from features.

**Preconditions:**
- Project has features

**Main Flow:**
1. System counts total features
2. System counts completed features
3. System calculates percentage:
   ```
   Progress = (Completed / Total) × 100%
   ```
4. System displays in project view

**Postconditions:**
- Project progress is calculated

---

## Module 9: Developer Hub - Bugs (UC-48 to UC-52)

### UC-48 — Create Bug

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-48 |
| **Name** | Create Bug |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Record a software bug or issue.

**Preconditions:**
- Project exists
- User is authenticated

**Main Flow:**
1. User navigates to project or bug list
2. User selects "Report Bug"
3. User enters bug details:
   - Title (required)
   - Description (required)
   - Steps to reproduce (optional)
   - Priority: Low/Medium/High/Critical
   - Status: Open/In Progress/Resolved/Closed
4. System validates input
5. System creates bug record
6. System updates bug count

**Postconditions:**
- Bug is recorded
- User can track resolution

---

### UC-49 — Edit Bug

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-49 |
| **Name** | Edit Bug |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Modify bug details.

**Preconditions:**
- Bug exists

**Main Flow:**
1. User selects bug
2. User chooses edit
3. System displays bug details
4. User modifies title, description, priority, or status
5. System validates changes
6. System saves updates

**Postconditions:**
- Bug is updated

---

### UC-50 — Resolve Bug

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-50 |
| **Name** | Resolve Bug |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Mark a bug as resolved when fixed.

**Preconditions:**
- Bug exists
- Bug is fixable

**Main Flow:**
1. User selects bug
2. User selects "Resolve"
3. User optionally adds resolution notes
4. System changes status to Resolved
5. System records resolution timestamp
6. System updates bug list

**Alternative Flows:**
- **A1: Bug not actually fixed** → User can reopen

**Postconditions:**
- Bug is resolved
- Bug list is updated

---

### UC-51 — Delete Bug

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-51 |
| **Name** | Delete Bug |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Rarely |

**Purpose:** Remove a bug record.

**Preconditions:**
- Bug exists

**Main Flow:**
1. User selects bug
2. User selects delete
3. System asks for confirmation
4. User confirms
5. System removes bug

**Postconditions:**
- Bug is removed

---

### UC-52 — Set Bug Priority

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-52 |
| **Name** | Set Bug Priority |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | During bug creation/editing |

**Purpose:** Assign urgency to bugs.

**Preconditions:**
- Bug exists

**Main Flow:**
1. User selects priority option
2. System provides levels:
   - **Critical**: System breaking, urgent
   - **High**: Major functionality affected
   - **Medium**: Some functionality affected
   - **Low**: Minor issue, nice to fix
3. User selects priority
4. System saves priority
5. System orders bugs by priority

**Postconditions:**
- Bug has priority assigned

---

## Module 10: GitHub (UC-53 to UC-59)

### UC-53 — Connect GitHub Account

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-53 |
| **Name** | Connect GitHub Account |
| **Actor** | Authenticated User, GitHub |
| **Priority** | Medium |
| **Frequency** | Once |

**Purpose:** Connect HabOS to GitHub for import and tracking.

**Preconditions:**
- User is authenticated
- User has GitHub account

**Main Flow:**
1. User selects "Connect GitHub"
2. System redirects to GitHub OAuth
3. User authorizes HabOS
4. GitHub returns access token
5. System stores token
6. System fetches user repositories
7. System imports repositories

**Alternative Flows:**
- **A1: Authorization denied** → System displays error and stays on HabOS

**Postconditions:**
- GitHub account is connected
- Repositories are imported

---

### UC-54 — Import Repositories

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-54 |
| **Name** | Import Repositories |
| **Actor** | Authenticated User, System |
| **Priority** | Medium |
| **Frequency** | On connection, manually refresh |

**Purpose:** Import user's GitHub repositories into HabOS.

**Preconditions:**
- GitHub account connected

**Main Flow:**
1. System fetches repositories from GitHub API
2. System displays repository list
3. User can select repositories to import
4. System creates projects for imported repositories
5. System links projects to GitHub

**Postconditions:**
- Repositories are imported as projects

---

### UC-55 — View GitHub Commits

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-55 |
| **Name** | View GitHub Commits |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Daily |

**Purpose:** Display commit activity.

**Preconditions:**
- GitHub account connected
- Repository imported

**Main Flow:**
1. User selects project
2. System fetches commits from GitHub
3. System displays:
   - Today: commit count
   - This week: commit count
   - This month: commit count
   - Recent commit list
4. System updates coding statistics

**Postconditions:**
- User sees commit activity

---

### UC-56 — View Contribution Statistics

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-56 |
| **Name** | View Contribution Statistics |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Show coding activity over time.

**Preconditions:**
- GitHub connected

**Main Flow:**
1. User navigates to GitHub stats
2. System displays:
   - Contribution graph (GitHub-style)
   - Daily commits
   - Weekly activity
   - Monthly trends
3. System shows coding streak

**Postconditions:**
- User sees contribution data

---

### UC-57 — View Pull Requests

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-57 |
| **Name** | View Pull Requests |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Track pull request activity.

**Preconditions:**
- GitHub connected

**Main Flow:**
1. User navigates to PR view
2. System displays:
   - Open PRs
   - Closed PRs
   - Merged PRs
   - Review requests
3. System shows PR statistics

**Postconditions:**
- User sees PR activity

---

### UC-58 — View Repository Activity

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-58 |
| **Name** | View Repository Activity |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** See recent repository activity.

**Preconditions:**
- GitHub connected

**Main Flow:**
1. User selects repository view
2. System shows:
   - Recent commits
   - Open issues
   - Recent PRs
   - Repository stats

**Postconditions:**
- User sees repository activity

---

### UC-59 — Track Coding Streak

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-59 |
| **Name** | Track Coding Streak |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Calculate consecutive days with qualifying coding activity.

**Preconditions:**
- GitHub connected
- Or coding sessions tracked

**Main Flow:**
1. System checks daily activity:
   - Commits > 0
   - or PRs created
   - or coding focus sessions > 30 minutes
2. System tracks consecutive days
3. System calculates current streak
4. System calculates longest streak
5. System displays on dashboard

**Postconditions:**
- Coding streak is tracked
- Motivation metric is available

---

## Module 11: LeetCode (UC-60 to UC-64)

### UC-60 — Connect LeetCode

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-60 |
| **Name** | Connect LeetCode |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Once |

**Purpose:** Connect LeetCode account for problem tracking.

**Preconditions:**
- User has LeetCode account

**Main Flow:**
1. User selects "Connect LeetCode"
2. User enters LeetCode username
3. System fetches public profile data
4. System imports problem-solving stats

**Postconditions:**
- LeetCode data is available

---

### UC-61 — Track Solved Problems

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-61 |
| **Name** | Track Solved Problems |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | Daily |

**Purpose:** Track total problems solved.

**Preconditions:**
- LeetCode connected

**Main Flow:**
1. System fetches solved count
2. System updates total
3. System tracks difficulty breakdown

**Postconditions:**
- Problem count is up to date

---

### UC-62 — Track Problem Difficulty

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-62 |
| **Name** | Track Problem Difficulty |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | Daily |

**Purpose:** Separate solved problems by difficulty.

**Preconditions:**
- LeetCode connected

**Main Flow:**
1. System fetches difficulty breakdown
2. System displays:
   - Easy: count
   - Medium: count
   - Hard: count
3. System updates analytics

**Postconditions:**
- Difficulty stats are available

---

### UC-63 — Track LeetCode Streak

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-63 |
| **Name** | Track LeetCode Streak |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | Continuous |

**Purpose:** Track consecutive days solving problems.

**Preconditions:**
- LeetCode connected

**Main Flow:**
1. System checks daily problem-solving activity
2. System tracks consecutive days
3. System calculates current streak
4. System displays on dashboard

**Postconditions:**
- LeetCode streak is tracked

---

### UC-64 — View LeetCode Statistics

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-64 |
| **Name** | View LeetCode Statistics |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Display comprehensive LeetCode stats.

**Preconditions:**
- LeetCode connected

**Main Flow:**
1. User navigates to LeetCode view
2. System displays:
   - Total problems solved
   - Difficulty breakdown
   - Daily solving graph
   - Current streak
   - Longest streak
3. System shows recent solved problems

**Postconditions:**
- User sees complete LeetCode stats

---

## Module 12: Technology Learning (UC-65 to UC-69)

### UC-65 — Add Technology

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-65 |
| **Name** | Add Technology |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Track technology learning progress.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Add Technology"
2. User enters:
   - Technology name
   - Current status: Not Started/Learning/Practicing/Completed
   - Progress percentage
   - Priority: Low/Medium/High
   - Resources (optional)
3. System validates input
4. System creates technology entry
5. System adds to learning list

**Postconditions:**
- Technology is tracked

---

### UC-66 — Set Learning Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-66 |
| **Name** | Set Learning Progress |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Update progress percentage for a technology.

**Preconditions:**
- Technology exists

**Main Flow:**
1. User selects technology
2. User updates progress (0-100%)
3. System saves progress
4. System updates status if completed (100% → Completed)

**Postconditions:**
- Progress is updated
- Status may change

---

### UC-67 — Update Learning Status

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-67 |
| **Name** | Update Learning Status |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Change the learning status of a technology.

**Preconditions:**
- Technology exists

**Main Flow:**
1. User selects technology
2. User selects status:
   - Not Started
   - Learning
   - Practicing
   - Completed
3. System updates status
4. System updates progress accordingly

**Postconditions:**
- Status is updated

---

### UC-68 — Add Learning Resource

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-68 |
| **Name** | Add Learning Resource |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Weekly |

**Purpose:** Attach resources to learning technology.

**Preconditions:**
- Technology exists

**Main Flow:**
1. User selects technology
2. User selects "Add Resource"
3. User enters:
   - Resource title
   - Resource type: Documentation/Course/Video/Book/Tutorial
   - URL or reference
   - Notes (optional)
4. System saves resource

**Postconditions:**
- Resource is attached

---

### UC-69 — View Learning Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-69 |
| **Name** | View Learning Progress |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Display all technology learning progress.

**Preconditions:**
- Technologies exist

**Main Flow:**
1. User navigates to Learning view
2. System displays technologies with:
   - Progress bars
   - Status indicators
   - Recently updated
3. System shows overall learning metrics

**Postconditions:**
- User sees learning progress

---

## Module 13: Student Hub (UC-70 to UC-83)

### UC-70 — Add Course

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-70 |
| **Name** | Add Course |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Semester/Quarter |

**Purpose:** Track university courses.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Add Course"
2. User enters:
   - Course name
   - Course code (optional)
   - Semester/Term
   - Instructor (optional)
   - Progress percentage
   - Credits (optional)
3. System validates input
4. System creates course

**Postconditions:**
- Course is created

---

### UC-71 — Edit Course

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-71 |
| **Name** | Edit Course |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Modify course details.

**Preconditions:**
- Course exists

**Main Flow:**
1. User selects course
2. User chooses edit
3. User modifies details
4. System saves changes

**Postconditions:**
- Course is updated

---

### UC-72 — Delete Course

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-72 |
| **Name** | Delete Course |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | End of semester |

**Purpose:** Remove a course.

**Preconditions:**
- Course exists

**Main Flow:**
1. User selects course
2. User selects delete
3. System asks for confirmation
4. User confirms
5. System archives course

**Postconditions:**
- Course is removed

---

### UC-73 — View Courses

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-73 |
| **Name** | View Courses |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Display all current courses.

**Preconditions:**
- Courses exist

**Main Flow:**
1. User navigates to Course view
2. System displays courses with:
   - Progress bars
   - Assignment counts
   - Upcoming exams
3. System shows current semester courses

**Postconditions:**
- User sees course list

---

### UC-74 — Set Course Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-74 |
| **Name** | Set Course Progress |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Update course completion progress.

**Preconditions:**
- Course exists

**Main Flow:**
1. User selects course
2. User updates progress
3. System saves progress

**Postconditions:**
- Course progress updated

---

### UC-75 — Add Assignment

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-75 |
| **Name** | Add Assignment |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Add an assignment for a course.

**Preconditions:**
- Course exists

**Main Flow:**
1. User selects course
2. User selects "Add Assignment"
3. User enters:
   - Assignment title
   - Description
   - Due date
   - Status: Not Started/In Progress/Submitted/Graded
4. System validates input
5. System creates assignment

**Postconditions:**
- Assignment is created

---

### UC-76 — Complete Assignment

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-76 |
| **Name** | Complete Assignment |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Mark assignment as completed.

**Preconditions:**
- Assignment exists

**Main Flow:**
1. User selects assignment
2. User marks as Submitted or Completed
3. System updates status
4. System updates course progress

**Postconditions:**
- Assignment is completed

---

### UC-77 — Track Assignment Deadline

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-77 |
| **Name** | Track Assignment Deadline |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Calculate days remaining for assignments.

**Preconditions:**
- Assignment has due date

**Main Flow:**
1. System calculates days until due date
2. System displays countdown:
   - Due in X days
   - Due today
   - Overdue by X days
3. System highlights approaching deadlines

**Postconditions:**
- User sees deadline status

---

### UC-78 — Add Exam

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-78 |
| **Name** | Add Exam |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Monthly |

**Purpose:** Record exam dates and details.

**Preconditions:**
- Course exists

**Main Flow:**
1. User selects course
2. User selects "Add Exam"
3. User enters:
   - Exam name
   - Date
   - Time (optional)
   - Exam type: Midterm/Final/Quiz
   - Weight (optional)
4. System validates input
5. System creates exam

**Postconditions:**
- Exam is recorded

---

### UC-79 — Track Exam Countdown

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-79 |
| **Name** | Track Exam Countdown |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Show days remaining until exams.

**Preconditions:**
- Exam exists

**Main Flow:**
1. System calculates days until exam
2. System displays countdown
3. System highlights approaching exams

**Postconditions:**
- Exam countdown is visible

---

### UC-80 — Record Grade

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-80 |
| **Name** | Record Grade |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | End of term |

**Purpose:** Record assignment or exam grades.

**Preconditions:**
- Assignment or exam exists

**Main Flow:**
1. User selects assignment/exam
2. User enters grade
3. System stores grade
4. System updates course average

**Postconditions:**
- Grade is recorded

---

### UC-81 — View Grades

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-81 |
| **Name** | View Grades |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Display academic performance.

**Preconditions:**
- Grades exist

**Main Flow:**
1. User navigates to Grades view
2. System displays:
   - Course grades
   - Assignment grades
   - Exam grades
   - Overall GPA (if calculated)
3. System shows trends

**Postconditions:**
- User sees academic performance

---

### UC-82 — Record Attendance

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-82 |
| **Name** | Record Attendance |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Daily |

**Purpose:** Record attendance for courses.

**Preconditions:**
- Course exists

**Main Flow:**
1. User selects course
2. User records attendance:
   - Present
   - Absent
   - Late
3. System stores attendance record
4. System calculates attendance percentage

**Postconditions:**
- Attendance is recorded

---

### UC-83 — View Attendance

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-83 |
| **Name** | View Attendance |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Display attendance statistics.

**Preconditions:**
- Attendance exists

**Main Flow:**
1. User navigates to Attendance view
2. System displays:
   - Attendance percentage per course
   - Total attended sessions
   - Absent/late records
3. System shows trends

**Postconditions:**
- User sees attendance data

---

## Module 14: Study (UC-84 to UC-90)

### UC-84 — Start Study Session

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-84 |
| **Name** | Start Study Session |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Begin a focused study session.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Start Study"
2. User optionally selects course
3. User optionally sets duration target
4. System starts timer
5. System tracks study duration

**Postconditions:**
- Study session is active

---

### UC-85 — End Study Session

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-85 |
| **Name** | End Study Session |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Conclude and record a study session.

**Preconditions:**
- Study session is active

**Main Flow:**
1. User selects "End Study"
2. System stops timer
3. System calculates duration
4. System prompts for notes (optional)
5. System saves session
6. System updates:
   - Course progress
   - Dashboard
   - Analytics

**Postconditions:**
- Study session is recorded
- Analytics are updated

---

### UC-86 — Record Study Duration

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-86 |
| **Name** | Record Study Duration |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Accumulate and store study time.

**Preconditions:**
- Study session exists

**Main Flow:**
1. System records start time
2. System records end time
3. System calculates duration
4. System stores duration

**Postconditions:**
- Study duration is stored

---

### UC-87 — Select Course for Study

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-87 |
| **Name** | Select Course for Study |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | During session setup |

**Purpose:** Associate study sessions with specific courses.

**Preconditions:**
- Course exists

**Main Flow:**
1. User starts study session
2. User selects course from list
3. System associates session with course
4. System updates course study time

**Postconditions:**
- Study is linked to course

---

### UC-88 — Add Study Notes

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-88 |
| **Name** | Add Study Notes |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | After sessions |

**Purpose:** Record what was learned during study.

**Preconditions:**
- Study session exists

**Main Flow:**
1. User ends study session
2. System prompts for notes
3. User enters what was learned
4. System saves notes
5. System links notes to session and course

**Postconditions:**
- Study notes are stored

---

### UC-89 — View Study History

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-89 |
| **Name** | View Study History |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Display past study sessions.

**Preconditions:**
- Study sessions exist

**Main Flow:**
1. User navigates to Study History
2. System displays sessions with:
   - Date
   - Duration
   - Course
   - Notes
3. System shows summary statistics

**Postconditions:**
- User sees study history

---

### UC-90 — View Study Statistics

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-90 |
| **Name** | View Study Statistics |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Display aggregated study metrics.

**Preconditions:**
- Study sessions exist

**Main Flow:**
1. User navigates to Study Stats
2. System displays:
   - Today: total hours
   - This week: total hours
   - This month: total hours
   - Course breakdown
   - Daily average
3. System shows trends

**Postconditions:**
- User sees study statistics

---

## Module 15: Gym (UC-91 to UC-101)

### UC-91 — Create Workout

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-91 |
| **Name** | Create Workout |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Create a workout routine or session.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "New Workout"
2. User enters:
   - Workout name
   - Date
   - Start time
   - Duration
   - Exercises to perform
3. System creates workout

**Postconditions:**
- Workout is created

---

### UC-92 — Add Exercise

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-92 |
| **Name** | Add Exercise |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | During workout creation |

**Purpose:** Add exercises to a workout.

**Preconditions:**
- Workout exists

**Main Flow:**
1. User selects workout
2. User selects "Add Exercise"
3. User searches or enters exercise name
4. User adds exercise to workout

**Postconditions:**
- Exercise is added

---

### UC-93 — Record Sets

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-93 |
| **Name** | Record Sets |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Per exercise |

**Purpose:** Record weight and reps for each set.

**Preconditions:**
- Exercise exists in workout

**Main Flow:**
1. User selects exercise
2. User adds set details:
   - Weight
   - Repetitions
   - Notes (optional)
3. System saves set record
4. System checks for personal record

**Postconditions:**
- Set is recorded

---

### UC-94 — Record Weight

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-94 |
| **Name** | Record Weight |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Per set |

**Purpose:** Track weight used for exercises.

**Preconditions:**
- Exercise exists

**Main Flow:**
1. User enters weight
2. System stores weight with set

**Postconditions:**
- Weight is recorded

---

### UC-95 — Record Repetitions

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-95 |
| **Name** | Record Repetitions |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Per set |

**Purpose:** Track repetitions performed.

**Preconditions:**
- Exercise exists

**Main Flow:**
1. User enters repetitions
2. System stores reps with set

**Postconditions:**
- Repetitions are recorded

---

### UC-96 — Record Personal Record

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-96 |
| **Name** | Record Personal Record |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Detect and celebrate new PRs.

**Preconditions:**
- Set exists
- Previous PR exists

**Main Flow:**
1. System checks if set exceeds previous PR:
   - More weight at same reps
   - More reps at same weight
   - Higher calculated 1RM
2. System detects new PR
3. System displays congratulations
4. System saves PR record
5. System notifies user

**Postconditions:**
- PR is recorded
- User is notified

---

### UC-97 — View Workout History

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-97 |
| **Name** | View Workout History |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Display past workouts.

**Preconditions:**
- Workouts exist

**Main Flow:**
1. User navigates to Workout History
2. System displays workouts with:
   - Date
   - Duration
   - Exercises performed
   - Notes
3. System shows exercise progression

**Postconditions:**
- User sees workout history

---

### UC-98 — Track Exercise Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-98 |
| **Name** | Track Exercise Progress |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | Continuous |

**Purpose:** Show strength improvement over time.

**Preconditions:**
- Exercise history exists

**Main Flow:**
1. System aggregates exercise data
2. System creates progress chart
3. System shows:
   - Weight progression
   - Volume progression
   - PR history
4. System displays trends

**Postconditions:**
- User sees exercise progress

---

### UC-99 — Record Body Weight

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-99 |
| **Name** | Record Body Weight |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Track body weight measurements.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Record Weight"
2. User enters weight
3. System stores measurement with date

**Postconditions:**
- Body weight is recorded

---

### UC-100 — Record Body Measurements

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-100 |
| **Name** | Record Body Measurements |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Monthly |

**Purpose:** Track body measurements.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Record Measurements"
2. User enters measurements:
   - Chest
   - Waist
   - Arms
   - Legs
   - Other
3. System stores with date

**Postconditions:**
- Measurements are recorded

---

### UC-101 — View Gym Analytics

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-101 |
| **Name** | View Gym Analytics |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Display comprehensive gym stats.

**Preconditions:**
- Gym data exists

**Main Flow:**
1. User navigates to Gym Analytics
2. System displays:
   - Training frequency
   - Strength progression chart
   - PR history
   - Body weight trend
   - Volume over time
3. System shows performance metrics

**Postconditions:**
- User sees gym analytics

---

## Module 16: Finance (UC-102 to UC-111)

### UC-102 — Add Income

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-102 |
| **Name** | Add Income |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly/Monthly |

**Purpose:** Record income transactions.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Add Income"
2. User enters:
   - Amount
   - Source (Salary, Freelance, Gift, etc.)
   - Date
   - Description (optional)
3. System validates input
4. System saves transaction

**Postconditions:**
- Income is recorded

---

### UC-103 — Add Expense

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-103 |
| **Name** | Add Expense |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Record expense transactions.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Add Expense"
2. User enters:
   - Amount
   - Category (Food, Transport, Education, etc.)
   - Date
   - Description (optional)
3. System validates input
4. System saves transaction
5. System updates budget tracking

**Postconditions:**
- Expense is recorded
- Budget is updated

---

### UC-104 — Edit Transaction

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-104 |
| **Name** | Edit Transaction |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Occasionally |

**Purpose:** Modify a transaction.

**Preconditions:**
- Transaction exists

**Main Flow:**
1. User selects transaction
2. User chooses edit
3. User modifies amount, category, or description
4. System validates changes
5. System saves updates
6. System recalculates budget

**Postconditions:**
- Transaction is updated
- Budget is recalculated

---

### UC-105 — Delete Transaction

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-105 |
| **Name** | Delete Transaction |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Occasionally |

**Purpose:** Remove a transaction.

**Preconditions:**
- Transaction exists

**Main Flow:**
1. User selects transaction
2. User selects delete
3. System asks for confirmation
4. User confirms
5. System removes transaction
6. System recalculates budget

**Postconditions:**
- Transaction is removed
- Budget is recalculated

---

### UC-106 — View Transactions

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-106 |
| **Name** | View Transactions |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Display financial transaction history.

**Preconditions:**
- Transactions exist

**Main Flow:**
1. User navigates to Transactions view
2. System displays transactions sorted by date
3. System shows:
   - Date
   - Description
   - Category
   - Amount (with +/- sign)
   - Running balance (optional)
4. User can filter by period or category

**Postconditions:**
- User sees transaction history

---

### UC-107 — Set Budget

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-107 |
| **Name** | Set Budget |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Monthly |

**Purpose:** Define spending limits by category.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Set Budget"
2. User enters budget amounts by category:
   - Food: 2,000 ETB
   - Transport: 1,000 ETB
   - Education: 1,500 ETB
   - etc.
3. System saves budget limits
4. System tracks spending against budget

**Postconditions:**
- Budget is set
- Tracking begins

---

### UC-108 — Track Budget

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-108 |
| **Name** | Track Budget |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Compare actual spending to budget.

**Preconditions:**
- Budget exists
- Expenses exist

**Main Flow:**
1. System aggregates expenses by category
2. System calculates percentage used:
   ```
   Used = (Spent / Budget) × 100%
   ```
3. System displays progress bars
4. System alerts if nearing limit (> 80%)

**Postconditions:**
- Budget tracking is visible

---

### UC-109 — Calculate Savings

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-109 |
| **Name** | Calculate Savings |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Calculate monthly savings.

**Preconditions:**
- Income and expenses exist

**Main Flow:**
1. System calculates total income for period
2. System calculates total expenses for period
3. System calculates savings:
   ```
   Savings = Income - Expenses
   ```
4. System displays savings

**Postconditions:**
- Savings is calculated

---

### UC-110 — View Financial Analytics

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-110 |
| **Name** | View Financial Analytics |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Display financial insights.

**Preconditions:**
- Financial data exists

**Main Flow:**
1. User navigates to Financial Analytics
2. System displays:
   - Income vs. Expenses chart
   - Spending by category (pie chart)
   - Budget usage
   - Savings trend
   - Monthly comparisons

**Postconditions:**
- User sees financial analytics

---

### UC-111 — View Monthly Financial Report

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-111 |
| **Name** | View Monthly Financial Report |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Provide comprehensive monthly financial summary.

**Preconditions:**
- Financial data exists for month

**Main Flow:**
1. User views Monthly Report
2. System displays:
   - Total income
   - Total expenses
   - Savings
   - Budget performance
   - Category breakdown
   - Monthly comparison
3. System formats as printable report

**Postconditions:**
- User sees monthly financial summary

---

## Module 17: Goals (UC-112 to UC-119)

### UC-112 — Create Goal

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-112 |
| **Name** | Create Goal |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Monthly |

**Purpose:** Define a long-term personal or professional goal.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "New Goal"
2. User enters:
   - Goal name (required)
   - Description (optional)
   - Target date (optional)
   - Priority: Low/Medium/High
   - Category: Career/Health/Education/Personal/Financial
3. System validates input
4. System creates goal with status "In Progress"

**Postconditions:**
- Goal is created

---

### UC-113 — Edit Goal

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-113 |
| **Name** | Edit Goal |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Modify goal details.

**Preconditions:**
- Goal exists

**Main Flow:**
1. User selects goal
2. User chooses edit
3. User modifies name, description, or deadline
4. System validates changes
5. System saves updates

**Postconditions:**
- Goal is updated

---

### UC-114 — Delete Goal

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-114 |
| **Name** | Delete Goal |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Rarely |

**Purpose:** Remove/archive a goal.

**Preconditions:**
- Goal exists

**Main Flow:**
1. User selects goal
2. User selects delete
3. System asks for confirmation
4. User confirms
5. System archives goal

**Postconditions:**
- Goal is archived

---

### UC-115 — Create Milestone

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-115 |
| **Name** | Create Milestone |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Break a goal into smaller, achievable milestones.

**Preconditions:**
- Goal exists

**Main Flow:**
1. User selects goal
2. User selects "Add Milestone"
3. User enters:
   - Milestone name
   - Description (optional)
   - Status: Not Started/In Progress/Completed
4. System creates milestone
5. System updates goal progress

**Postconditions:**
- Milestone is created
- Goal progress is updated

---

### UC-116 — Complete Milestone

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-116 |
| **Name** | Complete Milestone |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Mark a milestone as completed.

**Preconditions:**
- Milestone exists

**Main Flow:**
1. User selects milestone
2. User marks as Completed
3. System updates status
4. System updates goal progress
5. System checks if all milestones completed

**Postconditions:**
- Milestone is completed
- Goal progress is updated

---

### UC-117 — Track Goal Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-117 |
| **Name** | Track Goal Progress |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Calculate overall goal completion.

**Preconditions:**
- Goal has milestones

**Main Flow:**
1. System counts total milestones
2. System counts completed milestones
3. System calculates percentage:
   ```
   Progress = (Completed / Total) × 100%
   ```
4. System displays progress bar
5. System updates dashboard

**Postconditions:**
- Goal progress is calculated

---

### UC-118 — Set Goal Deadline

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-118 |
| **Name** | Set Goal Deadline |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | During goal creation/editing |

**Purpose:** Assign a target completion date.

**Preconditions:**
- Goal exists

**Main Flow:**
1. User selects goal
2. User sets target date
3. System saves deadline
4. System starts countdown
5. System adds to dashboard

**Postconditions:**
- Goal has deadline

---

### UC-119 — View Goal Analytics

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-119 |
| **Name** | View Goal Analytics |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Display goal-related metrics.

**Preconditions:**
- Goals exist

**Main Flow:**
1. User navigates to Goal Analytics
2. System displays:
   - Overall progress
   - Completion rate
   - Missed deadlines
   - Milestone history
   - Timeline

**Postconditions:**
- User sees goal analytics

---

## Module 18: Knowledge Vault (UC-120 to UC-130)

### UC-120 — Create Note

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-120 |
| **Name** | Create Note |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Daily |

**Purpose:** Store knowledge, ideas, and information.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "New Note"
2. User enters:
   - Title (required)
   - Content (required)
   - Category (optional)
   - Tags (optional)
3. System validates input
4. System creates note
5. System adds to Knowledge Vault

**Postconditions:**
- Note is created

---

### UC-121 — Edit Note

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-121 |
| **Name** | Edit Note |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Modify a note.

**Preconditions:**
- Note exists

**Main Flow:**
1. User selects note
2. User chooses edit
3. User modifies title or content
4. System saves changes

**Postconditions:**
- Note is updated

---

### UC-122 — Delete Note

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-122 |
| **Name** | Delete Note |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Occasionally |

**Purpose:** Remove a note.

**Preconditions:**
- Note exists

**Main Flow:**
1. User selects note
2. User selects delete
3. System asks for confirmation
4. User confirms
5. System removes note

**Postconditions:**
- Note is removed

---

### UC-123 — Categorize Note

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-123 |
| **Name** | Categorize Note |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | During note creation |

**Purpose:** Assign a category for organization.

**Preconditions:**
- Note exists

**Main Flow:**
1. User selects category from list:
   - Frontend
   - Backend
   - Database
   - DevOps
   - Cybersecurity
   - Algorithms
   - General
2. User can also create custom category
3. System saves category

**Postconditions:**
- Note has category

---

### UC-124 — Add Code Example

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-124 |
| **Name** | Add Code Example |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Attach code snippets to notes.

**Preconditions:**
- Note exists

**Main Flow:**
1. User selects note
2. User selects "Add Code"
3. User pastes code
4. User selects language for syntax highlighting
5. System saves code block

**Postconditions:**
- Code is attached to note

---

### UC-125 — Add Useful Command

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-125 |
| **Name** | Add Useful Command |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Store useful terminal commands.

**Preconditions:**
- Note exists

**Main Flow:**
1. User selects note
2. User selects "Add Command"
3. User enters command
4. User adds description (optional)
5. System saves command

**Postconditions:**
- Command is stored

---

### UC-126 — Record Mistake

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-126 |
| **Name** | Record Mistake |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Document technical mistakes and solutions.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Record Mistake"
2. User enters:
   - What happened
   - What was the error
   - How it was solved
   - Prevention tips
3. System stores as structured note
4. System adds tags: #mistake #solution

**Postconditions:**
- Mistake is recorded
- Solution is documented

---

### UC-127 — Add Learning Summary

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-127 |
| **Name** | Add Learning Summary |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | After learning sessions |

**Purpose:** Summarize what was learned.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User selects "Add Learning Summary"
2. User enters:
   - What I learned
   - What was difficult
   - What I should remember
   - Key takeaways
3. System saves summary
4. System links to relevant technology or course

**Postconditions:**
- Learning summary is saved

---

### UC-128 — Search Knowledge

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-128 |
| **Name** | Search Knowledge |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Find information in the Knowledge Vault.

**Preconditions:**
- Notes exist

**Main Flow:**
1. User enters search terms
2. System searches note titles and content
3. System displays matching results
4. User can filter by category or tag

**Postconditions:**
- User finds relevant notes

---

### UC-129 — Tag Knowledge

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-129 |
| **Name** | Tag Knowledge |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | During note creation/editing |

**Purpose:** Add tags for better organization and search.

**Preconditions:**
- Note exists

**Main Flow:**
1. User adds tags to note
2. System stores tags
3. System indexes for search
4. System shows related notes by tag

**Postconditions:**
- Note has tags
- Search is enhanced

---

### UC-130 — Link Related Notes

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-130 |
| **Name** | Link Related Notes |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Occasionally |

**Purpose:** Connect related knowledge.

**Preconditions:**
- Notes exist

**Main Flow:**
1. User selects note
2. User selects "Link to Note"
3. User searches for related note
4. User selects note
5. System creates bidirectional link

**Postconditions:**
- Notes are linked

---

## Module 19: AI Assistant (UC-131 to UC-143)

### UC-131 — Ask AI Question

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-131 |
| **Name** | Ask AI Question |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Get insights and answers from personal data.

**Preconditions:**
- User is authenticated
- Data exists in relevant modules

**Main Flow:**
1. User opens AI Assistant
2. User types question:
   - "What did I accomplish this week?"
   - "How's my coding progress?"
   - "What should I focus on today?"
   - "How am I doing on my goals?"
3. System analyzes relevant data
4. System generates response
5. System displays answer

**Alternative Flows:**
- **A1: No data for query** → System suggests adding data or refining question

**Postconditions:**
- User receives insight
- Answer is displayed

---

### UC-132 — Analyze Personal Data

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-132 |
| **Name** | Analyze Personal Data |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Continuous |

**Purpose:** Process and understand user data.

**Preconditions:**
- Data exists

**Main Flow:**
1. System collects data from:
   - Tasks
   - Projects
   - Goals
   - Coding (GitHub, LeetCode)
   - Study
   - Gym
   - Habits
   - Finance
2. System identifies patterns
3. System prepares insights
4. System stores analysis for queries

**Postconditions:**
- Data is analyzed
- Insights are available

---

### UC-133 — Generate Daily Recommendation

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-133 |
| **Name** | Generate Daily Recommendation |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Suggest what to focus on today.

**Preconditions:**
- User data exists

**Main Flow:**
1. System evaluates:
   - Task deadlines
   - Task priorities
   - Goal progress
   - Available time (from schedule)
   - Recent progress
   - Neglected areas
2. System ranks recommendations
3. System displays top 3-5 recommendations

**Postconditions:**
- User receives daily recommendations

---

### UC-134 — Generate Weekly Summary

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-134 |
| **Name** | Generate Weekly Summary |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Create a weekly activity overview.

**Preconditions:**
- Data exists for the week

**Main Flow:**
1. System aggregates weekly data
2. System creates summary:
   - Coding: 14h, 47 commits
   - Study: 8h, 2 courses
   - Gym: 4 sessions
   - Tasks: 47 completed
   - Expenses: 2,450 ETB
   - Habits: 85% completion
3. System formats summary
4. System displays or emails

**Postconditions:**
- Weekly summary is generated

---

### UC-135 — Generate Monthly Summary

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-135 |
| **Name** | Generate Monthly Summary |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Create comprehensive monthly report.

**Preconditions:**
- Data exists for the month

**Main Flow:**
1. System aggregates monthly data
2. System creates detailed report
3. System highlights trends
4. System shows comparisons to previous months

**Postconditions:**
- Monthly summary is generated

---

### UC-136 — Analyze Productivity

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-136 |
| **Name** | Analyze Productivity |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | On request |

**Purpose:** Identify productivity patterns.

**Preconditions:**
- Tasks, focus, and completion data exist

**Main Flow:**
1. System analyzes:
   - Task completion rates
   - Focus session patterns
   - Peak productivity times
   - Day of week productivity
2. System generates insights
3. System displays findings

**Postconditions:**
- Productivity insights are available

---

### UC-137 — Analyze Spending

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-137 |
| **Name** | Analyze Spending |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | On request |

**Purpose:** Understand financial patterns.

**Preconditions:**
- Financial data exists

**Main Flow:**
1. System analyzes:
   - Spending by category
   - Monthly trends
   - Unusual patterns
   - Budget performance
2. System generates insights
3. System displays findings

**Postconditions:**
- Spending insights are available

---

### UC-138 — Analyze Coding Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-138 |
| **Name** | Analyze Coding Progress |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | On request |

**Purpose:** Evaluate coding and development progress.

**Preconditions:**
- Coding data exists

**Main Flow:**
1. System analyzes:
   - Projects progress
   - Commit activity
   - Learning progress
   - LeetCode progress
   - Coding time
2. System generates insights
3. System displays findings

**Postconditions:**
- Coding progress insights are available

---

### UC-139 — Analyze Study Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-139 |
| **Name** | Analyze Study Progress |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | On request |

**Purpose:** Evaluate study and academic progress.

**Preconditions:**
- Study data exists

**Main Flow:**
1. System analyzes:
   - Study hours
   - Course progress
   - Grades
   - Exam preparation
   - Assignment completion
2. System generates insights
3. System displays findings

**Postconditions:**
- Study progress insights are available

---

### UC-140 — Analyze Gym Progress

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-140 |
| **Name** | Analyze Gym Progress |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | On request |

**Purpose:** Evaluate fitness and strength progress.

**Preconditions:**
- Gym data exists

**Main Flow:**
1. System analyzes:
   - Workout frequency
   - Strength progression
   - PR history
   - Body weight trends
2. System generates insights
3. System displays findings

**Postconditions:**
- Gym progress insights are available

---

### UC-141 — Recommend Next Tasks

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-141 |
| **Name** | Recommend Next Tasks |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | On request |

**Purpose:** Suggest what to do next based on context.

**Preconditions:**
- Tasks exist

**Main Flow:**
1. System evaluates:
   - Task priorities
   - Deadlines
   - Energy level (if tracked)
   - Time available
   - Dependencies
2. System ranks tasks
3. System recommends next task

**Postconditions:**
- Task recommendation is provided

---

### UC-142 — Identify Neglected Areas

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-142 |
| **Name** | Identify Neglected Areas |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | On request |

**Purpose:** Highlight areas receiving insufficient attention.

**Preconditions:**
- Data exists across modules

**Main Flow:**
1. System evaluates activity across all areas
2. System identifies areas with low activity
3. System generates alert
4. System recommends attention

**Postconditions:**
- Neglected areas are identified

---

### UC-143 — Generate Personalized Plan

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-143 |
| **Name** | Generate Personalized Plan |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | On request |

**Purpose:** Create a structured plan to achieve a goal.

**Preconditions:**
- Goal exists

**Main Flow:**
1. User states a goal/objective
2. System evaluates existing:
   - Goals
   - Projects
   - Knowledge
   - Schedule
   - Resources
3. System creates structured plan with:
   - Milestones
   - Timelines
   - Learning resources
   - Task recommendations
4. System displays plan

**Postconditions:**
- Personalized plan is generated

---

## Module 20: Analytics (UC-144 to UC-154)

### UC-144 — View Weekly Analytics

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-144 |
| **Name** | View Weekly Analytics |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Weekly |

**Purpose:** Display weekly performance metrics.

**Preconditions:**
- Data exists for the week

**Main Flow:**
1. User navigates to Analytics
2. System displays weekly metrics:
   - Tasks: completed, overdue
   - Focus: total time
   - Coding: commits, time
   - Study: time, progress
   - Gym: sessions, PRs
   - Habits: completion rate
   - Finance: income, expenses
3. System shows charts

**Postconditions:**
- User sees weekly analytics

---

### UC-145 — View Monthly Analytics

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-145 |
| **Name** | View Monthly Analytics |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Monthly |

**Purpose:** Display monthly performance metrics.

**Preconditions:**
- Data exists for the month

**Main Flow:**
1. User navigates to Monthly Analytics
2. System displays monthly metrics
3. System shows trends
4. System compares to previous months

**Postconditions:**
- User sees monthly analytics

---

### UC-146 — Compare Periods

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-146 |
| **Name** | Compare Periods |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Compare performance between periods.

**Preconditions:**
- Data exists for selected periods

**Main Flow:**
1. User selects two periods
2. System compares metrics:
   - This week vs. last week
   - This month vs. last month
   - Custom comparison
3. System shows differences
4. System calculates percentage changes

**Postconditions:**
- Period comparison is displayed

---

### UC-147 — View Productivity Trends

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-147 |
| **Name** | View Productivity Trends |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Show productivity over time.

**Preconditions:**
- Productivity data exists

**Main Flow:**
1. User navigates to Productivity Trends
2. System displays:
   - Daily completion rate
   - Weekly trends
   - Monthly trends
   - Peak productivity times
3. System shows charts

**Postconditions:**
- Productivity trends are visible

---

### UC-148 — View Coding Trends

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-148 |
| **Name** | View Coding Trends |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Show coding activity trends.

**Preconditions:**
- Coding data exists

**Main Flow:**
1. User navigates to Coding Trends
2. System displays:
   - Daily coding time
   - Commit activity
   - Project progress
   - Problem-solving progress
3. System shows charts

**Postconditions:**
- Coding trends are visible

---

### UC-149 — View Study Trends

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-149 |
| **Name** | View Study Trends |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Show study activity trends.

**Preconditions:**
- Study data exists

**Main Flow:**
1. User navigates to Study Trends
2. System displays:
   - Daily study time
   - Course progress
   - Grade trends
3. System shows charts

**Postconditions:**
- Study trends are visible

---

### UC-150 — View Gym Trends

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-150 |
| **Name** | View Gym Trends |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Show gym progress trends.

**Preconditions:**
- Gym data exists

**Main Flow:**
1. User navigates to Gym Trends
2. System displays:
   - Training frequency
   - Strength progression
   - Body weight trends
3. System shows charts

**Postconditions:**
- Gym trends are visible

---

### UC-151 — View Financial Trends

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-151 |
| **Name** | View Financial Trends |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Show financial trends.

**Preconditions:**
- Financial data exists

**Main Flow:**
1. User navigates to Financial Trends
2. System displays:
   - Income vs. expenses
   - Spending by category
   - Savings trend
   - Budget performance
3. System shows charts

**Postconditions:**
- Financial trends are visible

---

### UC-152 — View Habit Trends

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-152 |
| **Name** | View Habit Trends |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Show habit completion trends.

**Preconditions:**
- Habit data exists

**Main Flow:**
1. User navigates to Habit Trends
2. System displays:
   - Completion rates
   - Streak history
   - Consistency patterns
3. System shows charts

**Postconditions:**
- Habit trends are visible

---

### UC-153 — Generate Weekly Report

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-153 |
| **Name** | Generate Weekly Report |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Create a comprehensive weekly report.

**Preconditions:**
- Data exists for the week

**Main Flow:**
1. System compiles weekly data
2. System creates report with:
   - Key metrics
   - Progress summary
   - Trends
   - Recommendations
3. System provides export option

**Postconditions:**
- Weekly report is generated

---

### UC-154 — Generate Monthly Report

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-154 |
| **Name** | Generate Monthly Report |
| **Actor** | System |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Create a comprehensive monthly report.

**Preconditions:**
- Data exists for the month

**Main Flow:**
1. System compiles monthly data
2. System creates report with:
   - Key metrics
   - Progress summary
   - Trends
   - Month-over-month comparison
   - Recommendations
3. System provides export option

**Postconditions:**
- Monthly report is generated

---

## Module 21: Life Score (UC-155 to UC-158)

### UC-155 — Calculate Life Score

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-155 |
| **Name** | Calculate Life Score |
| **Actor** | System |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Compute a weighted consistency score.

**Preconditions:**
- Data exists in at least one area
- Weights are configured

**Main Flow:**
1. System calculates scores for each area:
   - Tasks: completion rate
   - Coding: consistency, progress
   - Study: consistency, progress
   - Gym: consistency, progress
   - Goals: milestone completion
   - Habits: completion rate
   - Finance: savings rate, budget
2. System normalizes each score (0-100)
3. System applies configured weights
4. System calculates composite score
5. System stores score

**Postconditions:**
- Life Score is calculated

---

### UC-156 — View Life Score

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-156 |
| **Name** | View Life Score |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Display the Life Score with breakdown.

**Preconditions:**
- Life Score is calculated

**Main Flow:**
1. User navigates to Life Score view
2. System displays:
   - Total score (0-100)
   - Area breakdown with scores
   - Change from previous period
   - Trend indicator
3. User can tap for details

**Postconditions:**
- User sees Life Score

---

### UC-157 — View Score Breakdown

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-157 |
| **Name** | View Score Breakdown |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** See detailed area scores and contributions.

**Preconditions:**
- Life Score is calculated

**Main Flow:**
1. User selects "Breakdown"
2. System displays:
   - Each area with score
   - Weight applied
   - Contribution to total
   - Historical trend
3. User can drill into areas

**Postconditions:**
- User sees score breakdown

---

### UC-158 — Compare Life Score

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-158 |
| **Name** | Compare Life Score |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Compare Life Score across periods.

**Preconditions:**
- Historical scores exist

**Main Flow:**
1. User selects comparison periods
2. System displays:
   - Score comparison
   - Area changes
   - Trend chart
3. System shows insights

**Postconditions:**
- User sees score comparison

---

## Module 22: Notifications (UC-159 to UC-166)

### UC-159 — Receive Task Reminder

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-159 |
| **Name** | Receive Task Reminder |
| **Actor** | User, Notification Service |
| **Priority** | High |
| **Frequency** | As scheduled |

**Purpose:** Remind user of tasks.

**Preconditions:**
- Task has due date
- Notification enabled

**Main Flow:**
1. System checks tasks
2. System sends notification:
   - "Task: [title] is due [today/tomorrow]"
3. User taps to open task

**Postconditions:**
- User receives reminder

---

### UC-160 — Receive Exam Reminder

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-160 |
| **Name** | Receive Exam Reminder |
| **Actor** | User, Notification Service |
| **Priority** | High |
| **Frequency** | As scheduled |

**Purpose:** Remind user of upcoming exams.

**Preconditions:**
- Exam exists
- Notification enabled

**Main Flow:**
1. System checks upcoming exams
2. System sends notification
3. User taps to view exam

**Postconditions:**
- User receives reminder

---

### UC-161 — Receive Goal Reminder

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-161 |
| **Name** | Receive Goal Reminder |
| **Actor** | User, Notification Service |
| **Priority** | Medium |
| **Frequency** | As scheduled |

**Purpose:** Remind user about goals.

**Preconditions:**
- Goal exists
- Notification enabled

**Main Flow:**
1. System checks:
   - Inactive goals
   - Goals approaching deadline
   - Goals lacking progress
2. System sends notification
3. User taps to view goal

**Postconditions:**
- User receives reminder

---

### UC-162 — Receive Habit Reminder

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-162 |
| **Name** | Receive Habit Reminder |
| **Actor** | User, Notification Service |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Remind user to complete habits.

**Preconditions:**
- Habit exists
- Reminder set
- Habit not completed

**Main Flow:**
1. System checks incomplete habits
2. System sends notification
3. User taps to mark complete

**Postconditions:**
- User receives reminder

---

### UC-163 — Receive Workout Reminder

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-163 |
| **Name** | Receive Workout Reminder |
| **Actor** | User, Notification Service |
| **Priority** | Medium |
| **Frequency** | As scheduled |

**Purpose:** Remind user of scheduled workouts.

**Preconditions:**
- Workout scheduled
- Notification enabled

**Main Flow:**
1. System checks scheduled workouts
2. System sends notification
3. User taps to start workout

**Postconditions:**
- User receives reminder

---

### UC-164 — Receive Budget Alert

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-164 |
| **Name** | Receive Budget Alert |
| **Actor** | User, Notification Service |
| **Priority** | High |
| **Frequency** | As triggered |

**Purpose:** Alert user about budget usage.

**Preconditions:**
- Budget exists
- Spending approaches limit

**Main Flow:**
1. System monitors budget usage
2. System triggers alert at thresholds:
   - 80% used → "Warning: [category] near limit"
   - 100% used → "Alert: [category] exceeded"
3. System sends notification

**Postconditions:**
- User receives budget alert

---

### UC-165 — Receive Streak Alert

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-165 |
| **Name** | Receive Streak Alert |
| **Actor** | User, Notification Service |
| **Priority** | Medium |
| **Frequency** | As triggered |

**Purpose:** Alert user about streaks at risk.

**Preconditions:**
- Streak exists
- Streak at risk

**Main Flow:**
1. System monitors active streaks
2. System triggers alert:
   - "Don't break your [X] day coding streak!"
   - "Your [habit] streak is at risk!"
3. System sends notification

**Postconditions:**
- User receives streak alert

---

### UC-166 — Manage Notifications

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-166 |
| **Name** | Manage Notifications |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | As needed |

**Purpose:** Configure all notification preferences.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Notification Settings
2. System displays:
   - All notification types
   - Delivery methods
   - Timing preferences
   - Quiet hours
3. User configures preferences
4. System saves settings

**Postconditions:**
- Notification settings are updated

---

## Module 23: Search (UC-167 to UC-172)

### UC-167 — Search Tasks

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-167 |
| **Name** | Search Tasks |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Daily |

**Purpose:** Find tasks by title or description.

**Preconditions:**
- Tasks exist

**Main Flow:**
1. User enters search query in task search
2. System searches task titles and descriptions
3. System displays matching tasks
4. User can filter results

**Postconditions:**
- Matching tasks are found

---

### UC-168 — Search Projects

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-168 |
| **Name** | Search Projects |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Find projects by name or description.

**Preconditions:**
- Projects exist

**Main Flow:**
1. User enters search query in project search
2. System searches project names
3. System displays matching projects

**Postconditions:**
- Matching projects are found

---

### UC-169 — Search Notes

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-169 |
| **Name** | Search Notes |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Daily |

**Purpose:** Find notes by title or content.

**Preconditions:**
- Notes exist

**Main Flow:**
1. User enters search query
2. System searches note content and titles
3. System displays matching notes

**Postconditions:**
- Matching notes are found

---

### UC-170 — Search Courses

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-170 |
| **Name** | Search Courses |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Weekly |

**Purpose:** Find courses by name.

**Preconditions:**
- Courses exist

**Main Flow:**
1. User enters search query
2. System searches course names
3. System displays matching courses

**Postconditions:**
- Matching courses are found

---

### UC-171 — Search Transactions

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-171 |
| **Name** | Search Transactions |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Weekly |

**Purpose:** Find financial transactions.

**Preconditions:**
- Transactions exist

**Main Flow:**
1. User enters search query
2. System searches:
   - Description
   - Category
   - Source
3. System displays matching transactions

**Postconditions:**
- Matching transactions are found

---

### UC-172 — Global Search

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-172 |
| **Name** | Global Search |
| **Actor** | Authenticated User |
| **Priority** | High |
| **Frequency** | Daily |

**Purpose:** Search across all HabOS modules.

**Preconditions:**
- Data exists across modules

**Main Flow:**
1. User enters search query in global search
2. System searches:
   - Tasks (titles, descriptions)
   - Projects (names, descriptions)
   - Goals (names, descriptions)
   - Notes (titles, content)
   - Courses (names)
   - Transactions (descriptions, categories)
3. System organizes results by module
4. System displays grouped results

**Search Results Example:**
```
Search: "Docker"

💻 Projects
  ├── HabOS (Uses Docker)
  └── DevOps Learning (Docker course)

🧠 Notes
  └── Docker Networking Basics

📚 Learning
  └── Docker (60% progress)

✅ Tasks
  └── Configure Docker Compose

🐛 Bugs
  └── Docker container crashes on startup
```

**Postconditions:**
- Cross-module results are displayed

---

## Module 24: Settings & Data Management (UC-173 to UC-182)

### UC-173 — Manage Profile

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-173 |
| **Name** | Manage Profile |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Manage personal account information.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Profile Settings
2. System displays:
   - Name
   - Email
   - Avatar
   - Time zone
   - Date format
3. User modifies fields
4. System validates changes
5. System saves updates

**Postconditions:**
- Profile is updated

---

### UC-174 — Configure Dashboard

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-174 |
| **Name** | Configure Dashboard |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Monthly |

**Purpose:** Customize what appears on the dashboard.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Dashboard Settings
2. System displays modules:
   - Coding
   - Study
   - Gym
   - Finance
   - Goals
   - Habits
   - Tasks
3. User toggles visibility
4. User can drag to reorder
5. System saves preferences

**Postconditions:**
- Dashboard is customized

---

### UC-175 — Configure Daily Targets

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-175 |
| **Name** | Configure Daily Targets |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Monthly |

**Purpose:** Set daily goals for activities.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Targets
2. User sets targets:
   - Coding: 2 hours/day
   - Study: 2 hours/day
   - Reading: 30 minutes/day
   - Gym: 4 times/week
3. System saves targets
4. System tracks against targets

**Postconditions:**
- Daily targets are set

---

### UC-176 — Configure Categories

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-176 |
| **Name** | Configure Categories |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | As needed |

**Purpose:** Create custom categories.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Category Settings
2. User creates new category:
   - Name
   - Color
   - Icon
3. System saves category
4. Category is available in all applicable modules

**Postconditions:**
- Custom categories are available

---

### UC-177 — Configure Life Score

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-177 |
| **Name** | Configure Life Score |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | As needed |

**Purpose:** Configure Life Score weights and components.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Life Score Settings
2. System displays areas with weights
3. User adjusts weights
4. System recalculates Life Score
5. System saves configuration

**Postconditions:**
- Life Score configuration is updated

---

### UC-178 — Configure Notifications

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-178 |
| **Name** | Configure Notifications |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | As needed |

**Purpose:** Configure all notification preferences.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Notification Settings
2. System displays all notification types
3. User configures each
4. System saves preferences

**Postconditions:**
- Notification configuration is updated

---

### UC-179 — Connect External Services

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-179 |
| **Name** | Connect External Services |
| **Actor** | Authenticated User |
| **Priority** | Medium |
| **Frequency** | Once |

**Purpose:** Connect third-party services.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Integrations
2. User selects service:
   - GitHub
   - LeetCode
   - Google Calendar (optional)
   - Apple Health (optional)
3. User authorizes connection
4. System stores credentials
5. System imports data

**Postconditions:**
- External service is connected

---

### UC-180 — Disconnect External Services

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-180 |
| **Name** | Disconnect External Services |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | As needed |

**Purpose:** Remove external service integration.

**Preconditions:**
- Service is connected

**Main Flow:**
1. User navigates to Integrations
2. User selects connected service
3. User chooses disconnect
4. System asks for confirmation
5. User confirms
6. System removes tokens
7. System stops data sync

**Postconditions:**
- External service is disconnected

---

### UC-181 — Export Personal Data

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-181 |
| **Name** | Export Personal Data |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | As needed |

**Purpose:** Export all personal data in portable format.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Data Export
2. User selects data to export:
   - All data
   - Specific modules
   - Date range
3. User selects format:
   - JSON
   - CSV (financial only)
   - PDF (reports)
4. System generates export
5. System provides download

**Postconditions:**
- User receives data export

---

### UC-182 — Delete Account

| Attribute | Description |
|-----------|-------------|
| **ID** | UC-182 |
| **Name** | Delete Account |
| **Actor** | Authenticated User |
| **Priority** | Low |
| **Frequency** | Rarely |

**Purpose:** Permanently delete the account and all data.

**Preconditions:**
- User is authenticated

**Main Flow:**
1. User navigates to Account Settings
2. User selects "Delete Account"
3. System displays consequences:
   - All data will be deleted
   - This action cannot be undone
   - Export data first (recommended)
4. User confirms with password
5. System deletes account
6. System logs user out
7. System redirects to login

**Postconditions:**
- Account and data are deleted

---

# System Relationships & Integration

## Key Relationships

### Task Completion Flow
```
Complete Task (UC-13)
    ├── Update Task Status
    ├── Update Project Progress (UC-42)
    ├── Update Goal Progress (UC-117)
    ├── Update Dashboard (UC-06)
    ├── Update Life Score (UC-155)
    └── Update Analytics (UC-144, UC-145)
```

### Study Session Flow
```
End Study Session (UC-85)
    ├── Record Duration (UC-86)
    ├── Update Course Progress (UC-74)
    ├── Update Study Statistics (UC-90)
    ├── Update Dashboard (UC-06)
    └── Update Analytics (UC-149)
```

### Workout Recording Flow
```
Record Workout (UC-91)
    ├── Record Sets (UC-93)
    ├── Record PR (UC-96)
    ├── Update Exercise Progress (UC-98)
    ├── Update Gym Analytics (UC-101)
    ├── Update Dashboard (UC-06)
    └── Update Life Score (UC-155)
```

### Expense Recording Flow
```
Add Expense (UC-103)
    ├── Record Transaction (UC-106)
    ├── Update Budget (UC-108)
    ├── Calculate Savings (UC-109)
    ├── Update Financial Analytics (UC-110)
    └── Update Life Score (UC-155)
```

### AI Assistant Flow
```
Ask AI Question (UC-131)
    ├── Analyze Personal Data (UC-132)
    │   ├── Analyze Productivity (UC-136)
    │   ├── Analyze Spending (UC-137)
    │   ├── Analyze Coding (UC-138)
    │   ├── Analyze Study (UC-139)
    │   └── Analyze Gym (UC-140)
    ├── Generate Response
    └── Display Insight
```
