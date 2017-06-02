import Foundation
import HexavilleFramework
import RedisSessionStore


let app = HexavilleFramework()

let session = SessionMiddleware(
    cookieAttribute: CookieAttribute(expiration: 3600, httpOnly: true, secure: false),
    store: RedisSessionStore()
)

app.use(session)

app.use { req, context in
    context.session?["now"] = "\(Date())"
    return .next(req)
}

let router = Router()

router.use(.get, "/") { req, context in
    if let now = context.session?["now"] {
        return Response(body: "current time is: \(now)")
    } else {
        return Response(body: "No session")
    }
}

app.use(router)

try app.run()
