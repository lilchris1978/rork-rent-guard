# Authentication, Push Notifications & Tenant Management

## What will be built

### Authentication — Google & Apple Sign-In
Sign in with Google or Apple using secure OAuth. Your profile saves per account, so multiple landlords or property managers can use RentGuard on the same device. The app shows a premium dark sign-in screen, and signing out returns you to it. Your existing profile setup flow merges in — after first sign-in, you set up your properties and preferences.

### Push Notifications
When a new emergency ticket arrives, the app sends you a local notification with the tenant name and issue summary, even if the app is in the background. The notification taps through to the ticket detail. Since real push servers aren't configured yet, emergency tickets trigger local notifications as they're created — giving you the same experience.

### Tenant Management
A new Tenants tab lets you build your tenant directory three ways:
- **Import from Contacts** — with your permission, pull tenant names, phone numbers, and emails from your phone's address book
- **Type Manually** — enter tenant name, phone, email, unit, lease dates, and notes
- **Import from Spreadsheet** — paste CSV data (copy from Google Sheets or Excel) to bulk-import tenants

Each tenant links to their property and unit, and their info appears in ticket details.

### UI Polish
- Spring animations on ticket transitions, filter changes, and status updates
- Haptics on important actions (resolving tickets, sending replies, marking emergencies)
- Animated empty states with subtle floating icons when no tickets or tenants exist
- Smooth tab transitions and card press effects throughout