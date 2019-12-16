# UnifiedContentCorrector
Exchange 2013 Exchange 2016 and Exchange 2019 fix Unified Content folder location for auto cleanup.


Exchange 2013, Exchange 2016, and Exchange 2019 if installed outside of the default directory (i.e. C:\Program Files) the UnifedContent Folder (Default file path: C:\Program Files\Microsoft\Exchange Server\V15\TransportRoles\data\Temp\UnifiedContent) is never updated or modifed to reflect an alternative installation location.


This causes a problem with the probe that checks that directory for files that need to be cleaned up resulting in excessive disk storage being used for temporary files that should be getting deleted, and would be if the Exchange server was installed in the default location.


This script corrects the Unified Content folder path so that the cleanup probe can check the directory for 
files that need to be cleaned up and removed. This only needs to be run on Exchange 2013, 2016, and 2019 servers
if both conditions are met.
 
    1.) Exchange 2013, 2016, 2019 installed outside of the default installation path (example C:\Program Files\Microsoft\Exchange Server\v15\)
    2.) You are actively utilizing the built in Antimalware agent.

If neither condition above applies to your scenario then this is a non-issue.

# Requirements

Script is unsigned, so you will need to change the PowerShell execution policy to unrestricted temporarily. You can do that by running the following:

Set-ExecutionPolicy unrestricted

After you run the script I highly recommend changing the execution policy back to restricted.

Set-ExecutionPolicy restricted

The script needs to be executed as an Administrator. I do have it check to confirm that it's being executed with Administrative privileges, and if not it will terminate the script and notify you.


