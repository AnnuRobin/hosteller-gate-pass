# SMS Parent Notification Feature - Setup Guide (v2: Postgres Trigger Edition)

## Overview
When a gate pass is **fully approved by HOD**, parents are automatically notified via SMS using MSG91 + Supabase Database Webhooks (`pg_net`). 

This runs **100% free** as part of your database server and does not consume any Edge Function quotas!

---

## Part 1: Flutter Code Changes ✅ DONE

The following changes were made:
- ✅ Removed Edge Function calls entirely! The backend handles it transparently when the Flutter app sets the status to `approved`.

---

## Part 2: Backend Database Setup (The Magic)

We are using a **PostgreSQL Trigger** + the `pg_net` extension to make HTTP calls safely to MSG91 straight from your database.

### 1. Enable `pg_net` Extension
1. Open the **Supabase Dashboard**.
2. Go to **Database** -> **Extensions**.
3. Search for **`pg_net`** and click **Enable**.

### 2. Enter and Run the SQL Script
1. Open the file `supabase/postgres_trigger_msg91.sql` from your project folder.
2. In the script, locate the MSG91 credentials variables (`YOUR_MSG91_AUTH_KEY` and `YOUR_SENDER_ID`).
3. Replace them with your actual MSG91 Authkey and Sender ID.
4. Go to **Supabase Dashboard** -> **SQL Editor**.
5. Paste the entire script and click **Run**.

---

## Part 3: MSG91 Setup

### 1. Get MSG91 Credentials

**MSG91 Authkey:**
- Go to https://control.msg91.com/
- Dashboard → API Key → Copy your Authkey

**MSG91 Sender ID:**
- Go to Dashboard → SMS → Sender ID
- If you don't have one, apply for a new sender ID (takes 1-2 days)
- Example: `HSTPASS`

---

## Part 4: How to Test

1. Ensure the parent's phone number is correctly in the `parentphno` column of your `users` table.
2. Log in to the Flutter app as Admin/HOD.
3. View pending gate pass requests currently approved by Advisor.
4. **Approve a request**.
5. The `hod_status` updates successfully in Supabase.
6. The Database **immediately** executes the hidden trigger, fetching the `parentphno` and calling the MSG91 url using `pg_net`.
7. You should receive the SMS!

---

## Troubleshooting

### SMS Not Sending?
- ✅ Check MSG91 Authkey is correct in the SQL function.
- ✅ Check MSG91 Sender ID is approved and correct in the SQL function.
- ✅ Verify the `parentphno` in the database is filled. (Must be 10 digits).
- ✅ Check if `pg_net` is perfectly enabled in Extensions.

### How to trace HTTP calls?
Because it fires in the database background via `pg_net`, you can view the response of the request by checking the `net.http_response` table. Run this in your Supabase SQL editor:
```sql
SELECT * FROM net.http_response ORDER BY created DESC LIMIT 5;
```
This will show you if the API call to MSG91 returned `200 OK` or threw an error message like "Invalid Auth Key".

---

## SMS Message Format

Parents will receive:
```
"Your child [Student Name] has been approved for a gate pass. Please find details in the hosteller app."
```
