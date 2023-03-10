// This file contains auto-generated code.
// Generated from `Microsoft.AspNetCore.Session, Version=7.0.0.0, Culture=neutral, PublicKeyToken=adb9793829ddae60`.

namespace Microsoft
{
    namespace AspNetCore
    {
        namespace Builder
        {
            public static class SessionMiddlewareExtensions
            {
                public static Microsoft.AspNetCore.Builder.IApplicationBuilder UseSession(this Microsoft.AspNetCore.Builder.IApplicationBuilder app) => throw null;
                public static Microsoft.AspNetCore.Builder.IApplicationBuilder UseSession(this Microsoft.AspNetCore.Builder.IApplicationBuilder app, Microsoft.AspNetCore.Builder.SessionOptions options) => throw null;
            }

            public class SessionOptions
            {
                public Microsoft.AspNetCore.Http.CookieBuilder Cookie { get => throw null; set => throw null; }
                public System.TimeSpan IOTimeout { get => throw null; set => throw null; }
                public System.TimeSpan IdleTimeout { get => throw null; set => throw null; }
                public SessionOptions() => throw null;
            }

        }
        namespace Session
        {
            public class DistributedSession : Microsoft.AspNetCore.Http.ISession
            {
                public void Clear() => throw null;
                public System.Threading.Tasks.Task CommitAsync(System.Threading.CancellationToken cancellationToken = default(System.Threading.CancellationToken)) => throw null;
                public DistributedSession(Microsoft.Extensions.Caching.Distributed.IDistributedCache cache, string sessionKey, System.TimeSpan idleTimeout, System.TimeSpan ioTimeout, System.Func<bool> tryEstablishSession, Microsoft.Extensions.Logging.ILoggerFactory loggerFactory, bool isNewSessionKey) => throw null;
                public string Id { get => throw null; }
                public bool IsAvailable { get => throw null; }
                public System.Collections.Generic.IEnumerable<string> Keys { get => throw null; }
                public System.Threading.Tasks.Task LoadAsync(System.Threading.CancellationToken cancellationToken = default(System.Threading.CancellationToken)) => throw null;
                public void Remove(string key) => throw null;
                public void Set(string key, System.Byte[] value) => throw null;
                public bool TryGetValue(string key, out System.Byte[] value) => throw null;
            }

            public class DistributedSessionStore : Microsoft.AspNetCore.Session.ISessionStore
            {
                public Microsoft.AspNetCore.Http.ISession Create(string sessionKey, System.TimeSpan idleTimeout, System.TimeSpan ioTimeout, System.Func<bool> tryEstablishSession, bool isNewSessionKey) => throw null;
                public DistributedSessionStore(Microsoft.Extensions.Caching.Distributed.IDistributedCache cache, Microsoft.Extensions.Logging.ILoggerFactory loggerFactory) => throw null;
            }

            public interface ISessionStore
            {
                Microsoft.AspNetCore.Http.ISession Create(string sessionKey, System.TimeSpan idleTimeout, System.TimeSpan ioTimeout, System.Func<bool> tryEstablishSession, bool isNewSessionKey);
            }

            public static class SessionDefaults
            {
                public static string CookieName;
                public static string CookiePath;
            }

            public class SessionFeature : Microsoft.AspNetCore.Http.Features.ISessionFeature
            {
                public Microsoft.AspNetCore.Http.ISession Session { get => throw null; set => throw null; }
                public SessionFeature() => throw null;
            }

            public class SessionMiddleware
            {
                public System.Threading.Tasks.Task Invoke(Microsoft.AspNetCore.Http.HttpContext context) => throw null;
                public SessionMiddleware(Microsoft.AspNetCore.Http.RequestDelegate next, Microsoft.Extensions.Logging.ILoggerFactory loggerFactory, Microsoft.AspNetCore.DataProtection.IDataProtectionProvider dataProtectionProvider, Microsoft.AspNetCore.Session.ISessionStore sessionStore, Microsoft.Extensions.Options.IOptions<Microsoft.AspNetCore.Builder.SessionOptions> options) => throw null;
            }

        }
    }
    namespace Extensions
    {
        namespace DependencyInjection
        {
            public static class SessionServiceCollectionExtensions
            {
                public static Microsoft.Extensions.DependencyInjection.IServiceCollection AddSession(this Microsoft.Extensions.DependencyInjection.IServiceCollection services) => throw null;
                public static Microsoft.Extensions.DependencyInjection.IServiceCollection AddSession(this Microsoft.Extensions.DependencyInjection.IServiceCollection services, System.Action<Microsoft.AspNetCore.Builder.SessionOptions> configure) => throw null;
            }

        }
    }
}
