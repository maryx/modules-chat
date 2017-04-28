# Chat

> Status: Experimental

# Structure

This repo contains code for running a [Fuchsia][fuchsia] specific set of Chat [modules][modular].

* **agents**: Fuchsia agents (background services) using Modular APIs.
  * **content_provider**: The chat content provider agent which communicates with the firebase DB and the [Ledger][ledger] instance.
* **modules**: Fuchsia application code using Modular APIs.
  * **conversation**: UI module for displaying chat messages for a conversatoin.
  * **conversation_list**: UI module for displaying the list of conversations.
  * **story**: The primary entry point for the full Chat experience.
* **services**: [FIDL][fidl] service definitions.

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

# Firebase DB Setup

The chat modules use the Firebase Realtime Database to send and receive chat
messages between users. This section describes what needs to be configured
before running the chat modules correctly.

## Setup

1. Create a new Firebase project [via the console](https://console.firebase.google.com/).
  * Navigate to Authentication and enable Google sign-in.
  * Under "Whitelist client IDs from external projects" add the client ID for an
    existing OAuth application. This will allow an extra scope to be added for
    that app's sign-in flow enabling Google authentication and authorization for
    this project.

1. Setup the security rules for realtime database.
  * Navigate to Database -> RULES from the Firebase console.
  * Set the security rules as follows:

    ```
    {
      "rules": {
        "users": {
          "$uid": {
            "email": {
              ".read": "auth != null",
              ".write": "$uid == auth.uid"
            },
            "messages": {
              ".read": "$uid == auth.uid",
              ".write": "auth != null",
            }
          }
        }
      }
    }
    ```

    This will ensure that users can send any messages to any signed up users and
    the messages can only be read by the designated recipients.

1. Authenticate with Google from the host side.
  * Run `make auth` command from `//apps/modules/common` repository to generate
    the `config.json` file under the same directory
    (See [instructions][auth-instructions]).
    Make sure that the `id_token` value is written in the `config.json` file.
  * Manually add the following values to the `config.json` file.
    * `"chat_firebase_api_key"`: `<web_api_key>`
    * `"chat_firebase_project_id"`: `<firebase_project_id>`
    * These two value can be found from your Firebase project console.
      Navigate to the Gear icon (upper-left side) -> Project settings.
    * Once you add these values, you don't have to add these later again, since
      `make auth` tool will preserve all the manually added key-values in the
      `config.json`.

# Running Tests

## Chat Agent Tests

To run the chat agent tests, build fuchsia with `--modules boot_test_modular`
option and boot into fuchsia using a target device or a QEMU instance.

```bash
$ fset --modules boot_test_modular
$ fbuild
$ frun <options> # when using QEMU.
```

Once the fuchsia device is booted, run the following command from the host.

```bash
$ $FUCHSIA_ROOT/apps/test_runner/src/run_test \
  --test_file=$FUCHSIA_ROOT/apps/modules/chat/tests/chat_tests.json
```

When the test passes, the resulting output should look like this:
```
Running chat_content_provider_test ..
./loglistener: listening on [::]33337 for device same-undo-rail-gains
.. pass
```

In case something fails, the script will output `fail`, and also print out the
fuchsia console messages with more detailed error logs.

Fore more details, refer to the [test_runner documentation][test-runner-doc].

# Firebase DB Authentication using REST APIs

(*NOTE: You can ignore this section if you're only interested in running the
chat app.*)

There is not a Fuchsia compatible Firebase package for Dart. The following is a
description of raw REST calls that the ChatContentProvider agent is doing behind
the scenes to enable message transport via Firebase Realtime DB.

User authentication is managed via an existing project's login flow. For that
flow to obtain to correct credentials it will need to be configured with an
additional scope: "https://www.googleapis.com/auth/plus.login".

When a user authenticates a JWT is returned in the response along with the
traditional OAuth tokens. This special token, `id_token` will be used in the
following call to the Google Identity Toolkit API. The following variables are
required to proceed:

```shell
    export FIREBASE_KEY="<web_api_key as above>"
    export FIREBASE_URL="https://<your_firebase_project_id>.firebaseio.com"
    export GOOGLE_ID_TOKEN="<JWT id_token from separate OAuth process>"
```

The following request is required for new users of the Firebase project
([identitytoolkit#VerifyAssertionResponse][identity-toolkit]):

    curl -Li -X POST \
      -H "accept: application/json" \
      -H "content-type: application/json" \
      -d "{ \"postBody\": \"id_token=${GOOGLE_ID_TOKEN}&providerId=google.com\", \"requestUri\": \"http://localhost\", \"returnIdpCredential\": true, \"returnSecureToken\": true}" \
      https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyAssertion?key=$FIREBASE_KEY

This call authenticates the Google API authenticated user with the Firebase
project. The JSON body of the response will have this
[schema][identity-toolkit-response].
Among the returned values, some useful ones include:
* `"localId"`: The Firebase User ID (UID) associated with this user.
* `"email"`  : Primary email address for this user.
* `"idToken"`: Auth token to be used in any subsequent REST API calls to the
  Firebase DB.  
  (Not to be confused with `oauthIdToken` value.)

Note that this new `idToken` is different from the original `GOOGLE_ID_TOKEN` we
used to make this call.

```shell
    export FIREBASE_USER_ID="<'localId' value from the response>"
    export FIREBASE_AUTH_TOKEN="<'idToken' value from the response>"
```

To grab the user's profile information use `$FIREBASE_AUTH_TOKEN` with  [identitytoolkit#GetAccountInfo](https://developers.google.com/identity/toolkit/web/reference/relyingparty/getAccountInfo):

    curl -Li -X POST \
      -H "accept: application/json" \
      -H "content-type: application/json" \
      -d "{ \"idToken\": \"${FIREBASE_AUTH_TOKEN}\" }" \
      https://www.googleapis.com/identitytoolkit/v3/relyingparty/getAccountInfo?key=$FIREBASE_KEY

This will return some useful profile data.

## Authorization

From here the database can be managed via the Firebase CLI or Firebase Console's
web UI for defining schemas etc. For example you can create a database rule for
users where only they can access their own data:

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

Once configured correctly publish the schema to the project with the Firebase
CLI or the Firebase Console. From here you can start working with records.

## Records
View the user's record.

```shell
curl -Li \
  -H "accept: application/json" \
  $FIREBASE_URL/users/$FIREBASE_USER_ID.json?auth=$FIREBASE_AUTH_TOKEN
```

Update the record.

```shell
curl -Li -X PUT \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  -d "{ \"uid\": \"${FIREBASE_USER_ID}\", \"username\": \"John Doe\" }" \
  $FIREBASE_URL/users/$FIREBASE_USER_ID.json?auth=$FIREBASE_AUTH_TOKEN
```

Stream updates.

```shell
curl -Li \
  -H "accept: text/event-stream" \
  $FIREBASE_URL/users/$FIREBASE_USER_ID.json?auth=$FIREBASE_AUTH_TOKEN
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
[ledger]: https://fuchsia.googlesource.com/ledger/
[auth-instructions]: https://fuchsia.googlesource.com/modules/common/+/master/README.md#Configure
[identity-toolkit]: https://developers.google.com/identity/toolkit/web/reference/relyingparty/verifyAssertion
[identity-toolkit-response]: https://developers.google.com/identity/toolkit/web/reference/relyingparty/verifyAssertion#response
[test-runner-doc]: https://fuchsia.googlesource.com/test_runner/+/master/README.md
