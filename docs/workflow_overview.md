# Workflow Overview

Work on a ticket usually begins by picking a ticket off of the prioritized [backlog][].  When development is done, the code is pushed up to this repository.  Github should automatically move the Jira ticket into the right location.  At this point, peer code review will commence and the [TeamCity iOS PR builder][tc] will begin building the application and running tests (if available).  If the build succeeds, the tests pass, and a peer approves the changes, then the code will be merged into the `develop` branch.

When merged into the `develop` branch, another [TeamCity build task][tcd] kicks off.  This one runs the above steps, but also runs additional security scans.  When the application is successfully built, the application will be moved to an internal test track in [AppCenter][ac].  At this point, the application will be ready for internal test evaluation.  If we find deficiencies in the build, we will evaluate whether they are blocking or whether we can note them as a known deficiency.  In the case of blocking deficiencies, we will either revert the changes from the branch and continue working or create a fix branch and merge it in through our normal processes.  This decision will be based on the severity of the issue, the expected cost to implement, and how close we are to a shipping deadline.

For UAT, we send links from AppCenter ([iOS][acios], [Android][acandroid]) for our point of contact at Donatos Village.  They then test these internal builds and provide feedback and approval.

This app is distributed privately through Apple Business Manager and is not released for the general public on the App Store. The release process is nearly identical to releasing an app to the App Store, except you will select "release privately" rather than "release publicly." #TODO link to ABM article

When we are ready to prepare a build for end users, we will create a release branch with our desired changes and make a git release with an associated tag. When that happens, another [TeamCity build agent][tcr] will rerun the security scans, rebuild the apps in the Release configuration, and create artifacts suitable for sending to App Store Connect.  When the build is complete, we use [Transporter][transporter] to put the application into TestFlight.  When it's finished processing by TestFlight, we create a new version of the application, choose the build that we just uploaded as the build for that version, and approve it for review.  We typically mark the boxes that allow us to ship immediately to every user and to ship as soon as the review is complete. We then merge our code from `develop` into `master`. 

[backlog]: https://jira.willowtreeapps.com/secure/RapidBoard.jspa?rapidView=395&projectKey=DV&view=detail
[tc]: https://builds.willowtreeapps.com/admin/editBuild.html?id=buildType:PineBranch_LiveTeam_DonatosVillage_DonatosVillageIOS_IOSPRs
[tcd]: https://builds.willowtreeapps.com/admin/editBuild.html?id=buildType:PineBranch_LiveTeam_DonatosVillage_DonatosVillageIOS_IOSDevelopOnly
[tcr]: https://builds.willowtreeapps.com/admin/editBuild.html?id=buildType:PineBranch_LiveTeam_DonatosVillage_DonatosVillageIOS_IOSReleaseOnly
[ac]: https://appcenter.ms/orgs/Live-Team-WT/apps/Donatos-Village-LT-iOS-Release
[acios]: https://appcenter.ms/orgs/Live-Team-WT/apps/Donatos-Village-LT-iOS-Release
[acandroid]: https://appcenter.ms/orgs/Live-Team-WT/apps/Donatos-Village-Android-Release
[transporter]: https://apps.apple.com/us/app/transporter/id1450874784?mt=12
