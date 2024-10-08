---
layout: post
title: How I Set Up Winforms Projects in Dotnet 8
description: Follow along as I demonstrate how I set up dotnet 8 WinForms projects with modern functionalities.
tags: [dotnet, dotnet8, net8, winforms, configuration, appconfig, serviceinjection, dependencyinversion, logging, structuredlogging]
published: true
---
# How I Set Up Winforms Projects in Dotnet 8

In this article, I'll share my initial experience building a .NET 8 solution with a WinForms client application. I'll cover how I set up configuration, logging, and generic hosting within the project, and discuss the UI patterns I've implemented. Along the way, I'll share what I enjoyed about this approach and reflect on areas that could be improved.

## Setting Up a .NET 8 Client App with Configuration, Hosting, and Logging

I began by creating a new repository on GitHub and cloned it using Visual Studio 2022. After that, I added a blank solution and named it ``GameLauncher.ClientApps.WinForms``.

I chose this naming convention to indicate that this solution is part of the larger GameLauncher project. Since this will be one of several client applications, I wanted the default namespace to clearly reflect its role within the overall structure.

Next, I added a WinForms project to the solution and named it ``Presentation``, which will serve as the user interface and startup project.

### AppSettings.json and Configuration Setup

Before addressing the ``Program.cs`` file, I created two JSON files named ``appsettings.json`` and ``appsettings.development.json``. For now, I'll leave it at these two, but later on, I may add an ``appsettings.production.json`` as well.

To configure our application to use these files, I added a small local method to the ``Program`` class, which will be referenced when setting up the host.

``` csharp
static void BuildConfig(IConfigurationBuilder builder)
{
    builder
        .SetBasePath(Directory.GetCurrentDirectory())
        .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
        .AddJsonFile(
            $"appsettings.{Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"}.json",
            optional: true
        )
        .AddEnvironmentVariables();
}
```

### Dependency Inversion and Service Injection

For dependency inversion, I set up a simple generic host using the ``Microsoft.Extensions.Hosting`` and ``Microsoft.Extensions.DependencyInjection`` packages.

After installing the required NuGet packages, I added another local method to the ``Program`` class to create, configure, and return an ``IHostBuilder`` object.

``` csharp
static IHostBuilder CreateHostBuilder() =>
    Host.CreateDefaultBuilder()
        // Setup App Configuration
        .ConfigureAppConfiguration(BuildConfig)
        // Setup App Services
        .ConfigureServices((ctx, services) =>
        {
            // Register the (required) app contexts
            services.AddSingleton<ApplicationContext, SplashScreenAppContext>();

            // Registers project services
            services.AddDesktopServices(ctx.Configuration);
        });
```

The first thing I set up is the builder's configuration, which will be used throughout the build process and the application. From there, I registered my primary application context and any other project services--initially, just my ``Application`` project, but later this will include any other projects in my solution where I want to inject services.

### Structured Logging with Serilog

I wanted to support structured logging in my application and chose to use the Serilog library. I installed the following three NuGet packages:

* ``Serilog.Extensions.Hosting``    
* ``Serilog.Settings.Configuration``
* ``Serilog.Sinks.Debug``

Once that was finished, I appended another method call to the end of the previous ``CreateHostBuilder()`` result to set up logging:

``` csharp
//Setup Logging
.UseSerilog((context, lc) => lc
    .ReadFrom.Configuration(context.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Debug()
);
```

With this, my ``HostBuilder`` is ready to go, complete with app configurations, structured logging, and service injection functionality.

### Putting It All Together in the Main Method

Finally, I updated the main entry point of the application to tie everything together. The Main method now looks like this:

``` csharp
[STAThread]
static void Main()
{
    // Setup application Host
    IHost host = CreateHostBuilder().Build();

    using IServiceScope serviceScope = host.Services.CreateScope();
    ServiceProvider = serviceScope.ServiceProvider;

    Log.Logger.Information("Application Starting.");

    // Setup application config
    ApplicationConfiguration.Initialize();
}
```

You may notice that I haven't instantiated the first form here. That's because, in the next post, I'll show you how to set up an application context, and we'll be launching that instead.

## Conclusion

One of the most challenging aspects of working with WinForms is the lack of built-in support for dependency inversion. Without it, projects can quickly devolve into a tangled web of dependencies, where every form, control, and component is tightly coupled, making the codebase difficult to maintain and almost impossible to unit test.

Introducing service injection helps create a more modular and testable codebase, despite adding some initial complexity. It requires thoughtful planning of your application's architecture and careful consideration of how your user interface components interact. However, the benefits are substantial: the ability to isolate and test individual components through interfaces, easier adherence to the Open/Closed Principle, and overall increased maintainability and productivity.

Adopting this approach can significantly improve your development experience by fostering a cleaner separation of concerns and a more maintainable solution structure.

As a next step, I'll consider implementing Passive View or Model-View-Presenter (MVP) patterns to further decouple UI logic from the presentation layer, making the application even more testable and maintainable.