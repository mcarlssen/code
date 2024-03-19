# Employee Census Audit Scripts

## Scope
Every month we receive an export of personnel data from HR, which we use as the source-of-truth to align all our paid subscription platforms. We use HR's ADP platform as the source of truth because it owns the UID that is assigned to every employee, and HR is responsible for the ultimate truthiness of that record, and the entire company relies on its accuracy for obvious reasons.

The audit script collection contains 5 primary scripts. Before any of these can be run, prepare the ADP data by the following steps:

1. Download or save the `XLS` file that HR sent. These should be copied to the `IT Team Drive > HR Census / Pay Period Reports` shared drive.
2. Open in Excel or LibreOffice. Save a copy in `CSV` format, fields comma-delimited, strings quote-delimited.
3. Log files from some scripts will be generated in the same folder as the CSV, so save it somewhere logical. Or not. Up to you.

## `update_google_employeeIDs`
**Prereqs**

`GAM` must be installed at `$HOME/bin/gam/gam`.

**Controls**

- Checks for ADP users that don't exist in Google, and vice-versa
- Confirms that ADP `Employee ID` matches Google `Associate ID` for all users
- Checks for Google users who match "Terminated" ADP status
- Checks for ADP 'Casual' users in Google 'Renovo Employees' OU
- Checks for ADP 'Active' users in Google 'Non-Renovo Employees' OU
- Checks for ADP 'Active' users in Google '2SV Bypass' OU
- Confirms membership for the following email groups:
  _[five groups redacted]_

**Howto:**

Run script with path to CSV (`update_google_employeeIDs.ps1 -Path <absolute path to CSV>`). Script will ingest data, run comparisons and checks, and output results throughout. 

If any Google users are found with missing or incorrect EmployeeIDs, the script will prompt to update the user records on an individual basis. If any of the checks (including Google `EmployeeID`) return more than 5 results, a log file will be generated alongside the original CSV file. 

If a log file is generated alongside the census file, it will contain user accounts that require manual review. This may simply be a mismatch between their ADP email and Renovo email, or may indicate user accounts assigned to former employees which were not properly terminated after the employee left the company. 

This file may also include user accounts who need to be added to various groups. This is not currently automated, but will be added in a future update.


# `update_m365_employeeIDs`
**Prereqs:**

Must have an active connection to Microsoft AzureAD running. Run `install_azuread.ps1` to install the AzureAD plugins, then run `Connect-AzureAD` and follow the steps to auth to the AAD server. Once this is done, execute the audit script in that terminal session.

**Controls:**

- Checks for ADP users in Office and compares EmployeeIDs
- Checks for ADP 'Terminated' users in Office

**Howto:**

1. Connect to AzureAD as noted in `Prereqs` section. 
2. Run script with path to CSV (`update_m365_employeeIDs.ps1 -Path <absolute path to CSV>`). Script will ingest ADP data, run checks and comparisons, and output results. 

If any result returns more than 5 results, a log file will be generated alongside the original CSV file. If Office users are found with missing or incorrect Office 365 `Associate ID` values, the script will prompt to update the user records on an individual basis.

Note that the Office employee ID's are not visible in the Office 365 admin portal - you need to be an `admin` to the Azure Active Directory portal to see the ID assigned to users. 


# `knowbe4_audit`
**Prereqs:**

_None._

**Controls:**

- Checks for ADP users in KnowBe4 and compares EmployeeIDs
- Checks for ADP 'Terminated' users who still exist in KnowBe4
- Checks for 'Manager email' in KnowBe4 user profile

**Howto:**

Run script with path to CSV (`knowbe4_audit.ps1 -Path <absolute path to CSV>`). The script will execute and compare ADP data to KnowBe4. Log files (or screen output if more than 5 results) will be generated for:
- KnowBe4 users missing an employee ID
- KnowBe4 users not matched to Active or Casual ADP employees
- KnowBe4 users with no listed manager email

KnowBe4 does not provide a writeable API at this time, so the output logs must be used to manually update the user records.


## `check_google_groups`
**Prereqs:**

`GAM` must be installed at `$HOME/bin/gam/gam`.

**Controls:**

- Checks for groups with zero members
- Checks for groups with open join settings

**Howto:**

Run script. No input parameters required. Results will output to screen if more than 5 actionable results found. If more, results will be output to `~/Downloads/Google_Group_Audit_<timestamp>.log`.


# `remoteaccess_audit`

_WIP._