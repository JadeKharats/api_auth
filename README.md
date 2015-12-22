Construire une API micro service auth avec sinatra et rethinkdb
==

Identifions les besoins
-

* Nous avons besoin d'identifier notre appelant ou consommateur.
* Ce consommateur a besoin de gérer les utilisateurs de notre API.
* Ce consommateur a besoin de stocker des données propres à son usage

Modele
-

on peut considérer que les consommateurs et les utilisateurs sont le même objet avec des droits différents.

USERS

| Champs              | Type     |
| ------------------- | -------- |
| id                  | integer  |
| login               | string   |
| password            | string   |
| salt                | string   |
| api_token           | string   |
| session_token       | string   |
| session_expire_date | datetime |
| created_at          | datetime |
| updated_at          | datetime |

Si on considère que nous allons avons besoin de laissé le schema libre d'être modifié (pour répondre à l'un des besoins), le stockage se fera en NoSQL. ici, ce sera RethinkDB

Les urls
-

| Verbe  | Urls           | Données                                     | Conditions       | Retour                                     |
| ------ | -------------- | ------------------------------------------- | ---------------- | ------------------------------------------ |
| GET    | /users         | API_TOKEN                                   | API_TOKEN valide | listes de tous les utilisateurs de la base |
| POST   | /users         | API_TOKEN + donnée utilisateur              | API_TOKEN valide | crée l'utilisateur si absent               |
| GET    | /users/:id     | API_TOKEN                                   | API_TOKEN valide | renvoie les infos de l'utilisateur :id     |
| PUT    | /users/:id     | API_TOKEN + donnée utilisateur              | API_TOKEN valide | mets à jours les infos utilisateur         |
| DELETE | /users/:id     | API_TOKEN                                   | API_TOKEN valide | supprime l'utilisateur                     |
|        |                |                                             |                  |                                            |
| POST   | /auth          | API_TOKEN + login/pwd                       | API_TOKEN valide | Token de session pour le login             |
| DELETE | /auth          | API_TOKEN + SESSION_TOKEN                   | API_TOKEN valide | supprime le token de sesssion en base      |
|        |                |                                             |                  |                                            |
| POST   | /token         | login/pwd d'un consommateur                 |                  | renvoie l'API_TOKEN du login               |

Premiers fichiers sinatra
-

Le fichier app.rb qui contient le code de l'api

```ruby
# app.rb
require 'sinatra/base'
require 'sinatra/json'

class App < Sinatra::Base

  users_list, users_create, users_show, users_update, users_delete, session_create, session_delete, token_show = lambda do
    json :response => 'Work in progress'
  end

  routes_missing = lambda do
    json :response => "Cette route n'existe pas"
  end

  get '/users', &users_list
  post '/users', &users_create
  get '/users/:id', &users_show
  put '/users/:id', &users_update
  delete '/users/:id', &users_delete

  post '/auth', &session_create
  delete '/auth', &session_delete

  post '/token', &token_show

  get '*', &routes_missing

end
```

le Gemfile avec les librairies necessaires.

```ruby
# Gemfile
source 'https://rubygems.org'

gem 'sinatra'             # La librairie sinatra
gem 'sinatra-contrib'     # Celle contenant la lib JSON
gem 'puma'                # Mon serveur web ruby préféré
```

Pour lancer le serveur web, ruby a besoin de savoir quoi faire. C'est dans le fichier config.ru que ça se passe

```ruby
require 'sinatra'
require './app.rb'

run App
```

en ligne de commande pour tester

```shell
$ puma
Puma starting in single mode...
* Version 2.15.3 (ruby 2.2.3-p173), codename: Autumn Arbor Airbrush
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://0.0.0.0:9292

$ curl http://0.0.0.0:9292/
{"response":"Cette route n'existe pas"}

$ curl http://0.0.0.0:9292/users
{"response":"Work in progress"}
```
