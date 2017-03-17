# Chat

> Status: Experimental

What exists here mostly boilerplate for the tooling and infrastructure needed
to build out the UI as a set of Flutter Widgets that can be run on Fuchsia and have the UI developed on Android.

# Structure

This repo contains code for running a vanilla [Flutter][flutter] application (iOS & Android) and a [Fuchsia][fuchsia] specific set of [modules][modular].

* **modules**: Fuchsia application code using Modular APIs.
  * **chat**: Is a Flutter app with two entry points, one for Fuchsia and one for Vanilla Flutter.

# Development

## Setup

This repo is already part of the default jiri manifest.

Follow the instructions for setting up a fresh Fuchsia checkout.  Once you have the `jiri` tool installed and have imported the default manifest and updated return to these instructions.

It is recommended you set up the [Fuchsia environment helpers][fuchsia-env] in `scripts/env.sh`:

    source scripts/env.sh

## Workflow

There are Makefile tasks setup to help simplify common development tasks. Use `make help` to see what they are.

When you have changes you are ready to see in action you can build with:

    make build

Once the system has been built you will need to run a bootserver to get it
over to a connected Acer. You can use the `env.sh` helper to move the build from your host to the target device with:

    freboot

Once that is done (it takes a while) you can run the application with:

    make run

You can run on a connected android device with:

    make flutter-run

Optional: In another terminal you can tail the logs

    ${FUCHSIA_DIR}/out/build-magenta/tools/loglistener

# Firebase

There is not a Fuchsia compatible Firebase package for Dart. The following is a description of raw REST calls and Firebase configuration that a client would need to handle in order to support an authenticated message transport and queue for Chat.

## Setup

1. Create a new Firebase project [via the console](https://console.firebase.google.com/).
* Navigate to Authentication and enable Google sign-in.
* Under "Whitelist client IDs from external projects" add the client ID for an existing OAuth application. This will allow an extra scope to be added for that app's sign-in flow enabling Google authentication and authorization for this project.

## Authenticate

User authentication is managed via an existing project's login flow. For that flow to obtain to correct credentials it will need to be configured with an additional scope: "https://www.googleapis.com/auth/plus.login".

When a user authenticates a JWT is returned in the response along with the traditional OAuth tokens. This special token, `id_token` will be used in subsequent calls to the Google Identity and Firebase REST APIs. The following variables are required to proceed:

```shell
    export FIREBASE_KEY="<from application settings>"
    export FIREBASE_URL="https://jxson-testing.firebaseio.com"
    export GOOGLE_AUTH_TOKEN="<from separate OAuth process>"
    export GOOGLE_ID_TOKEN="<JWT id_token from separate OAuth process>"
```

Two requests are required for new users, the first is to [identitytoolkit#VerifyAssertionResponse](https://developers.google.com/identity/toolkit/web/reference/relyingparty/verifyAssertion):

    curl -Li -X POST \
      -H "accept: application/json" \
      -H "content-type: application/json" \
      -d "{ \"postBody\": \"id_token=${GOOGLE_ID_TOKEN}&providerId=google.com\", \"requestUri\": \"http://localhost\", \"returnIdpCredential\": true, \"returnSecureToken\": true}" \
      https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyAssertion?key=$FIREBASE_KEY

This will respond with a [identitytoolkit#VerifyAssertionResponse](https://developers.google.com/identity/toolkit/web/reference/relyingparty/verifyAssertion), note that there is a new JWT id_token returned. This will need to be used in a subsequent call to the Identity API to retrieve profile information.

Additionally the return value for `localId` will be used in the Firebase Authorization schemes, save it for later as well.

```shell
    export GOOGLE_IDENTITY_ID_TOKEN="<from verify assertion response>"
    export FIREBASE_USER_ID="<from verify assertion response>"
```

To grab the user's profile information use `$GOOGLE_IDENTITY_ID_TOKEN` with  [identitytoolkit#GetAccountInfo](https://developers.google.com/identity/toolkit/web/reference/relyingparty/getAccountInfo):

    curl -Li -X POST \
      -H "accept: application/json" \
      -H "content-type: application/json" \
      -d "{ \"idToken\": \"${GOOGLE_IDENTITY_ID_TOKEN}\" }" \
      https://www.googleapis.com/identitytoolkit/v3/relyingparty/getAccountInfo?key=$FIREBASE_KEY

This will return some useful profile data.

## Authorization

From here the database can be managed via the Firebase CLI for defining schemas etc. For example you can create a database rule for users where only they can access their own data:

    {
      "rules": {
        ".read": "auth != null",
        ".write": "auth != null",

        "users": {
          "$uid": {
            ".read": "$uid === auth.uid",
            ".write": "$uid === auth.uid"
          }
        }
      }
    }

Once configured correctly upload the schema to the project with the Firebase CLI. From here you can start working with records.

## Records
View the user's record.

    ```shell
    curl -Li \
      -H "accept: application/json" \
      $FIREBASE_URL/users/$FIREBASE_USER_ID.json?access_token=$GOOGLE_AUTH_TOKEN
    ```

Update the record.

    ```shell
    curl -Li -X PUT \
      -H "accept: application/json" \
      -H "content-type: application/json" \
      -d "{ \"uid\": \"${FIREBASE_USER_ID}\", \"username\": \"John Doe\" }" \
      $FIREBASE_URL/users/$FIREBASE_USER_ID.json?access_token=$GOOGLE_AUTH_TOKEN
    ```

Stream updates.

    ```shell
    curl -Li \
      -H "accept: text/event-stream" \
      https://jxson-testing.firebaseio.com/users/$FIREBASE_USER_ID.json?access_token=$GOOGLE_AUTH_TOKEN
    ```

[flutter]: https://flutter.io/
[fuchsia]: https://fuchsia.googlesource.com/fuchsia/
[modular]: https://fuchsia.googlesource.com/modular/
[pub]: https://www.dartlang.org/tools/pub/get-started
[dart]: https://www.dartlang.org/
[fidl]: https://fuchsia.googlesource.com/fidl/
[widgets-intro]: https://flutter.io/widgets-intro/
[fuchsia-setup]: https://fuchsia.googlesource.com/fuchsia/+/HEAD/README.md
[fuchsia-env]: https://fuchsia.googlesource.com/fuchsia/+/HEAD/README.md#Setup-Build-Environment
[clang-wrapper]: https://fuchsia.googlesource.com/magenta-rs/+/HEAD/tools
