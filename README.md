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

Premier refactor
-

On peut observer trois type d'url, donc on a essayer de couper en trois controller.
On va donc créer le repertoire `controllers` et modifié le `config.ru`.

```shell
mkdir controllers
```

Nous allons y créer 4 controllers : Application, User, Auth et Token

```shell
cd controllers
touch application_controller.rb user_controller.rb auth_controller.rb token_controller.rb
```

Dans chacun des controllers, nous allons mettre ce que nous avions dans le `app.rb` puis enlever ce qui ne concerne plus le controller.

```ruby
# application_controller.rb
require 'sinatra/base'
require 'sinatra/json'

class ApplicationController < Sinatra::Base

  routes_missing = lambda do
    json :response => "Cette route n'existe pas"
  end

  get '*', &routes_missing

end
```

```ruby
# auth_controller.rb
require 'sinatra/base'
require 'sinatra/json'

class AuthController < Sinatra::Base

  session_create = session_delete  = lambda do
    json :response => 'Work in progress'
  end

  routes_missing = lambda do
    json :response => "Cette route n'existe pas"
  end


  post '/auth', &session_create
  delete '/auth', &session_delete

  get '*', &routes_missing

end
```

```ruby
# token_controller.rb
require 'sinatra/base'
require 'sinatra/json'

class TokenController < Sinatra::Base

  token_show = lambda do
    json :response => 'Work in progress'
  end

  routes_missing = lambda do
    json :response => "Cette route n'existe pas"
  end


  post '/token', &token_show

  get '*', &routes_missing

end
```

```ruby
# user_controller.rb
require 'sinatra/base'
require 'sinatra/json'

class UserController < Sinatra::Base

  users_list =  users_create =  users_show = users_update = users_delete = lambda do
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

  get '*', &routes_missing

end
```

Ìl faut maintenant modifier le `config.ru` pour appeler ces controllers plutot que le `app.rb`

```ruby
# config.ru
require 'sinatra'

Dir.glob('./{controllers}/*.rb').each { |file| require file }

map('/users') {run UserController}
map('/auth') {run AuthController}
map('/token') {run TokenController}
map('/') {run ApplicationController}
```

En modifiant le `config.ru`, on se rends comptes que l'url est doublonnée. il faut retirer des paths du controller la partie ajouter dans le `config.ru`
Ainsi, dans le UserController par exemple.
Ceci

```ruby
  get '/users', &users_list
  post '/users', &users_create
  get '/users/:id', &users_show
  put '/users/:id', &users_update
  delete '/users/:id', &users_delete
```

devient

```ruby
  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete
```

Deuxieme refactor
-

On va factoriser dans l'ApplicationController ce qui peut l'être et en faire hérité les autres controllers.

On ne change pas l'Application controller.
En revanche, les autres sont modifiés comme suit :

```ruby
# user_controller.rb
class UserController < ApplicationController

  users_list =  users_create =  users_show = users_update = users_delete = lambda do
    json :response => 'Work in progress'
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

end
```

```ruby
# auth_controller.rb
class AuthController < ApplicationController

  session_create = session_delete  = lambda do
    json :response => 'Work in progress'
  end

  post '/', &session_create
  delete '/', &session_delete

end
```

```ruby
# token_controller.rb
class TokenController < ApplicationController

  token_show = lambda do
    json :response => 'Work in progress'
  end

  post '/', &token_show

end
```

Pour que tout celà fonctionne, il faut s'assuser que ruby charge l'ApplicationController avant les autres.

```ruby
# config.ru
require 'sinatra'

require_relative 'controllers/application_controller'

Dir.glob('./{controllers}/*.rb').each { |file| require file }

map('/users') {run UserController}
map('/auth') {run AuthController}
map('/token') {run TokenController}
map('/') {run ApplicationController}
```
