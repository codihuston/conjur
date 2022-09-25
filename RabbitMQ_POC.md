# RabbitMQ POC

Goals:

- Define a RabbitMQ policy in Conjur
- Reboot Conjur with `CONJUR_ENABLE_RABBITMQ=true`
- When coming up, Conjur:
  - Fetches the RabbitMQ vars from policy
  - Connects
  - Creates a queue for every HOST LAYER defined in the policy
  - Cache HOST LAYERS in memory
- When a secret is rotated and `CONJUR_ENABLE_RABBITMQ=true`
  - Determine HOST LAYERS that can read this secret
  - Filter down to HOST LAYERS that were cached earlier
  - Publish this secret name (full resource id or otherwise) to the queue
    named after each of those HJOST LAYERS

## How to replicate

Start the server:

```bash
cd dev
./start --rabbitmq
# start the server
conjurctl server
```

Load the policy (from the conjur container):

```bash
cd dev

# print the admin key if you need it
./cli key

# load host policy and record host api key
conjur policy load root BotApp.yml

# set a secret
conjur variable values add BotApp/secretVar $(openssl rand -hex 32)
```

> Note: remember to save output somewhere nearby.

Start the bot app:

```bash
# start service
docker-compose up --no-deps -d bot_app

# get into container
docker-compose exec bot_app bash

# set conjur token
HOST_API_KEY=1gxb4mh8jf12c3dqfzk92x58gpb3vzzgn03sxmadtn71pf038g3mzm
curl -d "$HOST_API_KEY" -k http://conjur:3000/authn/cucumber/host%2FBotApp%2FmyDemoApp/authenticate > /tmp/conjur_token
cat /tmp/conjur_token

# run the app (app uses conjur token)
ruby app.rb
```

At this point, the `app.rb` script is running in the `bot_app` container:

1. Should be subscribed to a rabbitmq queue named `hello`
2. Should be fetching / printing the secret value
3. When a message is published to this queue, the `subscribe` block will fire
   and trigger a re-fetching of the secret and writing it to the in-memory cache
4. You should see the secret print loop re-fetch the secret, update the cache,
   and print the new value!

The pattern for simulating this process would be:

1. Assuming the `app.rb` script is running in the `bot_app` container...
1. Update the secret

    ```bash
    docker-compose exec conjur bash
    conjur init -u conjur -a cucumber
    conjur authn login
    conjur variable values add BotApp/secretVar $(openssl rand -hex 32)
    ```


2. Publish a message

    You can simulate a message publish event by visiting `localhost:8000`,
    authenticating with `user/password`, navigating to the `Queues` tab, selecting
    this queue, and publishing a message. You should publish a message with
    the un-urlencoded secret name, i.e.) `BotApp/secretVar`
