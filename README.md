# teamleader-powerbi
Custom connector to import Teamleader data in Power Bi.

As a recent side project for a Power BI dashboard, I had to import data from Teamleader. Since the API of Teamleader requires Oauth2, I had to use a custom connector to get my data. After quite some research I adapted an existing custom connector for another API. It took some time to get the details right, but I tought others could benefit from it when needed or refine it (it's not the cleanest code)!

Important steps:
- You need Visual Studio.
- You have to install some extra packages (Power Query SDK if I remember correctly).
- You need to work in the .pq and query.pq files.
- You need to build it and put the .mez file in EXACTLY this place: C:\Users\gebruiker\Documents\Microsoft Power Bi Desktop\Custom Connectors (or in English of course)
- For the authentication you need the powerbi url as found in the code.
- You need to make a Teamleader app and plug the id and secret into the .pq file.

Considerations and things to improve if you feel the urge to contribute:
- There is no strategy in the code that takes into account the Teamleader rate limits.
- I hard coded the Teamleader API endpoint and filters, which is not ideal of course.
- The mechanics do not take into account any available webhooks mechanics of Teamleader, therefore it feels like an inefficient 'polling' strategy. This is obviously not ideal if you have a lot of data and bring it all in every time!

Different strategies:
- For a durable more clever strategy, I would consider FastApi & MySQL that syncs more intelligently with Teamleader (updating only changes to Teamleader via webhooks). In Fastapi I would consider a simpler authentication strategy between the FastAPI endpoints and Power Bi itself. No rocket science, but as any developer will tell you there is a big gap between a POC and a production-grade solution.
- You can also buy an existing database strategy like the one I describe, but hey what's the fun in buying when you can build it yourself :D

If you need any help with this code, don't hesitate to contact me at: maxime@responsestudios.com.
