# Todo API Sample using Arcade

This sample is aimed to be a (somewhat) real world sample and project structure for an Arcade application. It has the
following features:

- Authentication using JWTs (Doesn't follow best practices, but is a good starting point)
- Database integration with Postgres via the [`drift`][drift] package
- Request validation using the [`luthor`][luthor] package
- Full CRUD operations

[drift]: https://pub.dev/packages/drift

[luthor]: https://pub.dev/packages/luthor

## Pre-requisites

You need to have [docker][docker] installed for running the local postgres instance. Alternatively, you can provide a
URL to a Postgres database in the `.env` file, replacing the local one we will add later on.

You will also need the following:

- [melos][melos] for running scripts (optional)
- [arcade_cli][arcade_cli] for serving a local dev version of the application

To install the above 2, you can run the following commands:

```shell
dart pub global activate melos
dart pub global activate arcade_cli
```

[docker]: https://www.docker.com/

[melos]: https://melos.invertase.dev

[arcade_cli]: https://pub.dev/packages/arcade_cli

## Getting started

Clone the arcade repository

```shell
git clone https://github.com/dartarcade/arcade.git
cd arcade
```

Bootstrap Melos

```shell
melos bs
```

Add a `.env` file in the root of `samples/todo_api`

```shell
cat <<EOF > .env
port=7331
databaseUrl=postgres://postgres:password@localhost:5432/todo?sslmode=disable
jwtSecret=secret
EOF
```

Run `build_runner`, `docker` and the dev server in separate terminals

```shell
# Terminal 1
melos run todo:build_runner

# Terminal 2
melos run todo:docker

# Terminal 3
melos run todo:serve
```

Once your docker containers and `build_runner` are up, you should see a log in the `melos run todo:serve` terminal like
`Server running on port 7331`

Once last step is to go to `http://locahost:5050` in your browser to access the PgAdmin web panel to manage your
postgres database. You can enter the email as `db@todo.com` and password as `password` to log in. Once you have logged
in, do the following steps to create a database called `todo` in order for our application to work:

- Right click on `Servers` and select `Register` -> `Server`
- Under `General`, add any name you'd like
- Under `Connection`, enter the following into the fields:
  - `Host name/address` -> `db`
  - `Username` -> `postgres`
  - `Password` -> `password`
  - Check `Save Password?` if you'd like
- Finally, click `Save`
- Once you created a connection, you should see the name you picked under `Servers`
- Under your server name, right click on `Databases`, then click `Create` -> `Database...`
- Enter `todo` in the field labeled `Database`. This is the name of the database
- Finally click on `Save`

Now you can run the APIs using a tool like `curl` or `Postman`. If you're using [`Bruno`][bruno] as your API client,
there is a `.bruno` folder you can import as a collection into Bruno

[bruno]: https://www.usebruno.com

The list of APIs are:

- `POST /auth/signup`
- `POST /auth/login`

Below endpoints require `Authentication` header to be set with token from login or regiser in the form of
`Bearer <token>`

- `GET /todos`
- `POST /todos`
- `PATCH /todos`
- `DELETE /todos`
