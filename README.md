Construire une API micro service auth avec sinatra et mongo
==

C'est quoi, un microservice?
-
http://www.touilleur-express.fr/2015/02/25/micro-services-ou-peon-architecture/
http://martinfowler.com/articles/microservices.html

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

J'utilise curl pour avoir quelquechose de facile à mettre dans ce document.
Mais je vous conseille le plugin chrome `postman` pour vous simplifier la vie.

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

Création du modèle User
-

Commençons par créer le fichier `models/user.rb`
```shell
mkdir models
touch models/user.rb
```

on modifie le config.ru pour charger les modeles
```ruby
require 'sinatra'

require_relative 'controllers/application_controller'

Dir.glob('./{models,controllers}/*.rb').each { |file| require file }

map('/users') {run UserController}
map('/auth') {run AuthController}
map('/token') {run TokenController}
map('/') {run ApplicationController}
```

Maintenant on crée le modele user avec plein de donnée bouchonnée dedans ;-)

```ruby
# user.rb
class User

  def initialize(login = 'itsme', password = 'plop1234')
    @id = 153
    @login = login
    @password = password
    @salt = SecureRandom.hex
    @api_token = SecureRandom.hex
    @session_token = SecureRandom.hex
    @session_expire_date = Time.now
    @created_at = Time.now
    @updated_at = Time.now
  end

end
```

Dans le user_controller.rb, on change la lambda pour charger un user

```ruby
# user_controller.rb
class UserController < ApplicationController

  users_list =  users_create =  users_show = users_update = users_delete = lambda do
    u1 = User.new
    json :response => u1.inspect
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

end
```

et on rajoute deux lignes au `config.ru`
```ruby
require 'securerandom'
require 'json'
```

on relance puma et ça fonctionne

```shell
curl localhost:9292/users
{"response":"#<User:0x000000016fb728 @id=153, @login=\"itsme\", @password=\"plop1234\", @salt=\"5fd481607a4fd51fe2d21919d7035237\", @api_token=\"292e401c582afc51cd034cdf6a96f0f6\", @session_token=\"dbae864efa5dd1fc69fe81a299165070\", @session_expire_date=2015-12-22 21:46:08 +0100, @created_at=2015-12-22 21:46:08 +0100, @updated_at=2015-12-22 21:46:08 +0100>"}
```

Ajout de l'orm Mongo
-
Nous allons utiliser mongoid. Il en existe d'autres comme mongo_mapper, candy,...

On commence par modifier le Gemfile :

```ruby
# Gemfile
source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'puma'

gem 'mongoid'
```

puis on lance un `bundle install`.

Il faut ensuite définir la connexion à la base. Pour celà, on va créer un fichier de config `mongoid.yml`

```yaml
# config/mongoid.yml
development:
  clients:
    default:
      database: auth_api
      hosts:
        - localhost:27017
```

Pour la production, on vera qu'il est mieux de mettre ces paramètres en variables d'environnement.

Maintenant, nous allons charger ces paramètres à partir du `config.ru`
```ruby
# config.ru
require 'sinatra'
require 'securerandom'
require 'json'
require 'mongoid'

require_relative 'controllers/application_controller'

Dir.glob('./{models,controllers}/*.rb').each { |file| require file }

Mongoid.load!("config/mongoid.yml")

map('/users') {run UserController}
map('/auth') {run AuthController}
map('/token') {run TokenController}
map('/') {run ApplicationController}
```

A ce stade, si on lance le serveur `puma` on doit voir :
```shell
$ puma
Puma starting in single mode...
* Version 2.15.3 (ruby 2.2.3-p173), codename: Autumn Arbor Airbrush
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://0.0.0.0:9292
Use Ctrl-C to stop
D, [2015-12-23T09:14:12.644902 #10026] DEBUG -- : MONGODB | Adding localhost:27017 to the cluster.ll
```

Enfin, nous allons modifier le modèle user pour le transformer en document mongo
```ruby
# models/user.rb
class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :login
  field :password
  field :salt
  field :api_token
  field :session_token
  field :session_expire_date

end
```

Le champ `id` est géré par mongoid. Les champs `created_at` et `updated_at` sont géré par `Mongoid::Timestamps`

Pour tester tout ça, on va demander à sinatra de créer un utilisateur à chaque appel sur '/users/'.

```ruby
# controllers/user_controller.rb
class UserController < ApplicationController

  users_list =  users_create =  users_show = users_update = users_delete = lambda do
    u1 = User.new
    u1.login = 'plop'
    u1.password = '1234'
    u1.save
    json :response => u1.inspect
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

end
```

on relance `puma` et on lance un curl

```shell
$ puma
Puma starting in single mode...
* Version 2.15.3 (ruby 2.2.3-p173), codename: Autumn Arbor Airbrush
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://0.0.0.0:9292
Use Ctrl-C to stop
D, [2015-12-23T09:25:43.215365 #10429] DEBUG -- : MONGODB | Adding localhost:27017 to the cluster.
```

```shell
$ curl localhost:9292/users
{"response":"#\u003cUser _id: 567a5a87f43a1c28bd000000, created_at: 2015-12-23 08:25:43 UTC, updated_at: 2015-12-23 08:25:43 UTC, login: \"plop\", password: \"1234\", salt: nil, api_token: nil, session_token: nil, session_expire_date: nil\u003e"}
```

Dans la console puma :
```shell
D, [2015-12-23T09:25:43.216707 #10429] DEBUG -- : MONGODB | localhost:27017 | auth_api.insert | STARTED | {"insert"=>"users", "documents"=>[{"_id"=>BSON::ObjectId('567a5a87f43a1c28bd000000'), "login"=>"plop", "password"=>"1234", "updated_at"=>2015-12-23 08:25:43 UTC, "created_at"=>2015-12-23 08:25:43 UTC}], "ordered"=>true}
```

Tout fonctionne bien.
Nous avons notre API, la persistance en mongo et les urls métiers.
On va maintenant s'attaquer au traitement.
A partir de maintenant, nous ne toucherons normalement plus au coté technique.

La validation du modèle user
-

Commençons par rajouter un peu de validation au modèle `user`. Si vous êtes comme moi et que vous avez fait plein de curl à l'étape précédente, vous avez pu observer que l'on peut créer une infinité de `user` ayant les mêmes valeurs.

```ruby
# models/user.rb
class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :login
  field :password
  field :salt
  field :api_token
  field :session_token
  field :session_expire_date

  validates :login, uniqueness: true

  validates :login, presence: true
  validates :password, presence: true
  validates :password, length: { minimum: 8, maximum: 16 }
end
```

Pensez à aller sur votre base mongo faire le ménage.

```shell
$ mongo
MongoDB shell version: 3.0.8
connecting to: test
> use auth_api
switched to db auth_api
> db.users.find()
{ "_id" : ObjectId("567a57d4f43a1c272a000000"), "login" : "plop", "password" : "1234" }
> db.users.find()
{ "_id" : ObjectId("567a57d4f43a1c272a000000"), "login" : "plop", "password" : "1234" }
{ "_id" : ObjectId("567a5a47f43a1c27c0000000"), "login" : "plop", "password" : "1234" }
> db.users.drop()
true
> db.users.find()
>
```

Le controller user
-

Commençons par le `get '/', &users_list`.

Nous avons juste besoin de renvoyer la liste des éléments en base.

```ruby
# controllers/user_controller.rb
class UserController < ApplicationController

  users_list =  lambda do
    json User.all
  end

  users_create =  users_show = users_update = users_delete = lambda do
    u1 = User.new
    u1.login = 'plop2'
    u1.password = '12345678'
    u1.api_token = 'qghfh'
    u1.save
    json :response => u1.inspect
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

end
```

on relance `puma` et notre curl

```shell
$ curl localhost:9292/users
[{"_id":{"$oid":"567a62d1f43a1c2cb8000000"},"api_token":null,"created_at":"2015-12-23T10:01:05.144+01:00","login":"plop","password":"12345678","salt":null,"session_expire_date":null,"session_token":null,"updated_at":"2015-12-23T10:01:05.144+01:00"},{"_id":{"$oid":"567a631af43a1c2e99000000"},"api_token":"qghfh","created_at":"2015-12-23T10:02:18.337+01:00","login":"plop2","password":"12345678","salt":null,"session_expire_date":null,"session_token":null,"updated_at":"2015-12-23T10:02:18.337+01:00"}]
```

Jusque là, c'est facile ;-)

la fonction user_show est tout aussi simple
```ruby
  users_show = lambda do
    json User.find_by(id: params[:id])
  end
```

pour le test, il faut prendre un des id renvoyé par le curl précédent. ici `567a631af43a1c2e99000000`

```shell
curl localhost:9292/users/567a631af43a1c2e99000000
{"_id":{"$oid":"567a631af43a1c2e99000000"},"api_token":"qghfh","created_at":"2015-12-23T10:02:18.337+01:00","login":"plop2","password":"12345678","salt":null,"session_expire_date":null,"session_token":null,"updated_at":"2015-12-23T10:02:18.337+01:00"}
```

En revanche, l'appel à un id inexistant génère une erreur. On modifie le controller pour prendre en compte ce cas.

```ruby
  users_show = lambda do
    if User.where(id: params[:id]).exists?
      json User.find(params[:id])
    else
      json :message => 'ID not found'
    end
  end
```

Nous allons créer des users maintenant.

```ruby
  users_create = lambda do
    user = User.new
    user.login = params[:login]
    user.password = params[:password]
    user.save
    json user
  end
```

si on teste avec un curl

```shell
$ curl --request POST 'http://localhost:9292/users' --data "login=jade&password=kharats01"
{"_id":{"$oid":"567a68d4f43a1c3c36000000"},"api_token":null,"created_at":"2015-12-23T10:26:44.848+01:00","login":"jade","password":"kharats01","salt":null,"session_expire_date":null,"session_token":null,"updated_at":"2015-12-23T10:26:44.848+01:00"}
```

Ok ça fonctionne. Par contre, il faut gérer d'autre cas comme un paramètre absent ou invalide.
On va d'abords finir tous les cas passants.

Il nous reste l'update et le delete.

Pour le delete, on reprends en partie le code du show

```ruby
  users_delete = lambda do
    if User.where(id: params[:id]).exists?
      User.where(id: params[:id]).destroy
      json :message => "ID #{params[:id]} destroy"
    else
      json :message => 'ID not found'
    end
  end
```

```shell
$ curl --request DELETE localhost:9292/users/567a631af43a1c2e99000000
{"message":"ID 567a631af43a1c2e99000000 destroy"}
$ curl --request DELETE localhost:9292/users/567a631af43a1c2e99000000
{"message":"ID not found"}
```

Le premier curl efface le `user` et le deuxieme confirme cette effacement.

Pour l'update, on cherche l'element passé en argument puis on change les paramètres envoyer en data du POST

```ruby
  users_update = lambda do
    if User.where(id: params[:id]).exists?
      user = User.find(params[:id])
      user.login = params[:login] if params[:login]
      user.password = params[:password] if params[:password]
      user.save
      json user
    else
      json :message => 'ID not found'
    end
  end
```

Testons en curl

```shell
$ curl --request GET localhost:9292/users/567a68d4f43a1c3c36000000
{"_id":{"$oid":"567a68d4f43a1c3c36000000"},"api_token":null,"created_at":"2015-12-23T10:26:44.848+01:00","login":"jade","password":"kharats01","salt":null,"session_expire_date":null,"session_token":null,"updated_at":"2015-12-23T10:26:44.848+01:00"}

$ curl --request PUT localhost:9292/users/567a68d4f43a1c3c36000000 --data 'password=tintagel'
{"_id":{"$oid":"567a68d4f43a1c3c36000000"},"api_token":null,"created_at":"2015-12-23T10:26:44.848+01:00","login":"jade","password":"tintagel","salt":null,"session_expire_date":null,"session_token":null,"updated_at":"2015-12-23T10:42:56.711+01:00"}
```

Seul le champ passé en argument de la requete PUT à été mis à jour.

Petit recap du fichier `controllers/users_controller.rb`
```ruby
# controllers/users_controller.rb
class UserController < ApplicationController

  users_list =  lambda do
    json User.all
  end

  users_show = lambda do
    if User.where(id: params[:id]).exists?
      json User.find(params[:id])
    else
      json :message => 'ID not found'
    end
  end

  users_delete = lambda do
    if User.where(id: params[:id]).exists?
      User.where(id: params[:id]).destroy
      json :message => "ID #{params[:id]} destroy"
    else
      json :message => 'ID not found'
    end
  end

  users_create = lambda do
    user = User.new
    user.login = params[:login]
    user.password = params[:password]
    user.save
    json user
  end

  users_update = lambda do
    if User.where(id: params[:id]).exists?
      user = User.find(params[:id])
      user.login = params[:login] if params[:login]
      user.password = params[:password] if params[:password]
      user.save
      json user
    else
      json :message => 'ID not found'
    end
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

end
```

Securisons le mot de passe
-

Pour se faire, nous allons utiliser la gem 'bcrypt' dont voici un exemple tiré de la rubydoc.
```ruby
include BCrypt

# hash a user's password
@password = Password.create("my grand secret")
@password #=> "$2a$10$GtKs1Kbsig8ULHZzO1h2TetZfhO4Fmlxphp8bVKnUlZCBYYClPohG"
```

On commence donc par ajouter `gem 'bcrypt'` a notre `Gemfile`.
On ajoute la ligne `require 'bcrypt'` dans le `config.ru`.
Enfin on relance un `bundle install`.


Ensuite nous allons modifier notre model `models/user.rb` pour stocker le hash du password au lieu du password. Et modifier le nom du champs pour eviter toute confusion.

```ruby
# models/user.rb
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  attr_accessor   :password

  field :login
  field :password_hash
  field :salt
  field :api_token
  field :session_token
  field :session_expire_date

  validates :login, uniqueness: true

  validates :login, presence: true
  validates :password, presence: true
  validates :password, length: { minimum: 8, maximum: 16 }

  before_save :encrypt_password

  protected

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
```

Relançons le serveur et regardons le résultat pour la création du `User`

```shell
 curl --request POST 'http://localhost:9292/users' --data "login=jade&password=kharats01"
{"_id":{"$oid":"568b79a6f43a1c101c000004"},"api_token":null,"created_at":"2016-01-05T09:07:02.537+01:00","login":"jade","password_hash":"$2a$10$ddjpgi5BQIwETAW2DYqIvugggxFR2f3rVpnfuAcu3XOlkf6hZ2pn.","salt":null,"session_expire_date":null,"session_token":null,"updated_at":"2016-01-05T09:07:02.537+01:00"}
```

On stocke bien le hash du password et non le password en lui même. BCrypt fournit le mecanisme de salt. Je n'ai plus besoin de prévoir son stockage. on supprime donc la ligne `field :salt` du model `user.rb`

Nous avons fait le tour pour l'API /users. On peut maintenant s'attaquer à l'API /auth.

L'API AUTH
-

L'API /auth va donc permettre de créer des sessions et d'en supprimer.

Commençons par la création. Pour celà, nous allons recevoir le couple login/password en POST, créer une nouvelle instance `User` et vérifier les identifiants. Allons-y!

Modifions le controller `controllers/auth_controller.rb`
```ruby
# controllers/auth_controller.rb
class AuthController < ApplicationController

  session_create = lambda do
    user = User.new
    json user.authenticate(params[:login],params[:password])
  end


  session_delete  = lambda do
    json :response => 'Work in progress'
  end

  post '/', &session_create
  delete '/', &session_delete

end
```

On peut voir que je fait appel à la méthode `authenticate`. Il va falloir la rajouter à notre modèle. Et utiliser un moyen de générer un token. Pour le token, nous allons utiliser `securerandom` qui est une librairie standard de ruby.

On charge la librairie dans le `config.ru` en ajoutant `require 'securerandom'`.

Puis on modifie le modèle `User` pour y ajouter la méthode `authenticate`.

```ruby
# models/users.rb
  def authenticate(login,password)
    user_in_db = User.where(login: login).first
    user_in_db.password = password
    if user_in_db
      if Password.new(user_in_db.password_hash) == password
        user_in_db.session_token = SecureRandom.urlsafe_base64
        user_in_db.session_expire_date = Time.now + 3 * 60 * 60
        user_in_db.save!
        return {token: user_in_db.session_token, session_expire_date: user_in_db.session_expire_date}am
      else
        return {message: 'Bad Bad Password'}
      end
    else
      return {message: "user #{login} not found!"}
    end
  end
```

Troisième refactor
-
En Réalisant quelques tests, je me suis rendu compte que mon callback `before_save :encrypt_password` me faisait grave c****. En effet, j'ai besoin de crypter le mot de passe à la création de l'utilisateur ou à sa modification. Mais là, je le réencrypte à chaque `save`. Depuis que j'ai rajouté les sessions, je fais souvent des `save`, ce qui me pose problème.

Je décide donc de supprimer le callback, et de déproteger la méthode `encrypt_password`.

```ruby
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  attr_accessor   :password

  field :login
  field :password_hash
  field :salt
  field :api_token
  field :session_token
  field :session_expire_date

  validates :login, uniqueness: true

  validates :login, presence: true
  validates :password, presence: true
  validates :password, length: { minimum: 8, maximum: 16 }

  def authenticate(login,password)
    user_in_db = User.where(login: login).first
    if user_in_db
      if Password.new(user_in_db.password_hash) == password
        user_in_db.session_token = SecureRandom.urlsafe_base64
        user_in_db.session_expire_date = Time.now + 3 * 60 * 60
        user_in_db.save!(validate: false)
        return {token: user_in_db.session_token, session_expire_date: user_in_db.session_expire_date}
      else
        return {message: 'Bad Bad Password'}
      end
    else
      return {message: "user #{login} not found!"}
    end
  end

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
```

Et dans le controller `user_controller.rb`

```ruby
class UserController < ApplicationController

  users_list =  lambda do
    json User.all
  end

  users_show = lambda do
    if User.where(id: params[:id]).exists?
      json User.find(params[:id])
    else
      json :message => 'ID not found'
    end
  end

  users_delete = lambda do
    if User.where(id: params[:id]).exists?
      User.where(id: params[:id]).destroy
      json :message => "ID #{params[:id]} destroy"
    else
      json :message => 'ID not found'
    end
  end

  users_create = lambda do
    user = User.new
    user.login = params[:login]
    user.password = params[:password]
    user.encrypt_password
    user.save
    json user
  end

  users_update = lambda do
    if User.where(id: params[:id]).exists?
      user = User.find(params[:id])
      user.login = params[:login] if params[:login]
      if params[:password]
        user.password = params[:password]
        user.encrypt_password
      end
      user.save
      json user
    else
      json :message => 'ID not found'
    end
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

end
```

Après un bon repas et une petite reflexion perso, je me dis que ça mérite encore un petit refacto des familles. En fait, j'aime pas trop ma methode `authenticate` qui n'authentifie pas vraiment. Je crée juste un token. Je vais découper ça de manière plus propre à mon goût. Je vous laisse juger par vous même.

```ruby
# models/user.rb
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  attr_accessor   :password

  field :login
  field :password_hash
  field :salt
  field :api_token
  field :session_token
  field :session_expire_date

  validates :login, uniqueness: true

  validates :login, presence: true
  validates :password, presence: true
  validates :password, length: { minimum: 8, maximum: 16 }

  def check_password? (password)
    Password.new(self.password_hash) == password
  end

  def create_token
    @session_token = SecureRandom.urlsafe_base64
    @session_expire_date = Time.now + 3 * 60 * 60
    self..save!(validate: false)
    format_token
  end

  def format_token
    {token: @session_token, session_expire_date: @session_expire_date}
  end

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
```

```ruby
# controllers/auth_controller.rb
class AuthController < ApplicationController

  session_create = lambda do
    user = User.where(login: params[:login]).first
    if user
      if user.check_password?(params[:password])
        json user.create_token
      else
        json :message => 'Bad credential'
      end
    else
      json :message => 'Bad credential'
    end
  end


  session_delete  = lambda do
    json :response => 'Work in progress'
  end

  post '/', &session_create
  delete '/', &session_delete

end
```

Detruire une session
-
Commençons par le controller

```ruby
# controllers/auth_controller.rb
class AuthController < ApplicationController

  session_create = lambda do
    user = User.where(login: params[:login]).first
    if user
      if user.check_password?(params[:password])
        json user.create_token
      else
        json :message => 'Bad credential'
      end
    else
      json :message => 'Bad credential'
    end
  end


  session_delete  = lambda do
    user = User.where(session_token: params[:token]).first
    if user
      user.remove_token
      json :message => 'Token destroyed'
    else
      json :message => 'Bad Token'
    end
  end

  post '/', &session_create
  delete '/', &session_delete

end
```

Et pour le modèle.

```ruby
# models/user.rb
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  attr_accessor   :password

  field :login
  field :password_hash
  field :salt
  field :api_token
  field :session_token
  field :session_expire_date

  validates :login, uniqueness: true

  validates :login, presence: true
  validates :password, presence: true
  validates :password, length: { minimum: 8, maximum: 16 }

  def check_password? (password)
    Password.new(self.password_hash) == password
  end

  def create_token
    self.session_token = SecureRandom.urlsafe_base64
    self.session_expire_date = Time.now + 3 * 60 * 60
    self.save!(validate: false)
    format_token
  end

  def format_token
    {token: self.session_token, session_expire_date: self.session_expire_date}
  end

  def remove_token
    self.session_token = nil
    self.session_expire_date = nil
    self.save!(validate: false)
  end

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
```

Générer un token d'accès à l'API
-

On va reprendre une partie du code de l'API /auth.

Pour le token, voici le `controllers/token_controller.rb`.

```ruby
# controllers/token_controller.rb
class TokenController < ApplicationController

  token_show = lambda do
    user = User.where(login: params[:login]).first
    if user
      if user.check_password?(params[:password])
        json user.create_api_token
      else
        json :message => 'Bad credential'
      end
    else
      json :message => 'Bad credential'
    end
  end

  post '/', &token_show

end
```

Pour le modèle `User`, voici une première version de la modification de la classe.

```ruby
# models/user.rb
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  attr_accessor   :password

  field :login
  field :password_hash
  field :api_token
  field :session_token
  field :session_expire_date

  validates :login, uniqueness: true

  validates :login, presence: true
  validates :password, presence: true
  validates :password, length: { minimum: 8, maximum: 16 }

  def check_password? (password)
    Password.new(self.password_hash) == password
  end

  def create_token
    self.session_token = SecureRandom.urlsafe_base64
    self.session_expire_date = Time.now + 3 * 60 * 60
    self.save!(validate: false)
    format_token
  end

  def format_token
    {token: self.session_token, session_expire_date: self.session_expire_date}
  end

  def remove_token
    self.session_token = nil
    self.session_expire_date = nil
    self.save!(validate: false)
  end

  def create_api_token
    self.api_token = SecureRandom.urlsafe_base64
    self.save!(validate: false)
    format_api_token
  end

  def format_api_token
    {token: self.api_token}
  end

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
```

Protégeons les autres API par le token
-

Nous allons créer un nouveau controller qui va vérifier la présence du token dans le header de chaque requête.
Je vais le nommer `ProtectedController` et utiliser le callback `before` pour la vérification.

Essayons ça!

```ruby
# controllers/protected_controller.rb
class ProtectedController < ApplicationController

  before do
    puts 'protected'
  end

end
```

et on fait hériter les controllers auth et user de ce controller.

```ruby
class AuthController < ProtectedController
class UserController < ProtectedController
```

Je lance le serveur et fait un curl pour voir si je passe bien dans le `before`

```shell
$ puma
Puma starting in single mode...
* Version 2.15.3 (ruby 2.2.3-p173), codename: Autumn Arbor Airbrush
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://0.0.0.0:9292
Use Ctrl-C to stop
protected
D, [2016-01-06T14:34:38.711328 #27651] DEBUG -- : MONGODB | Adding localhost:27017 to the cluster.
D, [2016-01-06T14:34:38.712945 #27651] DEBUG -- : MONGODB | localhost:27017 | auth_api.find | STARTED | {"find"=>"users", "filter"=>{"login"=>"jade"}, "limit"=>-1}
```

Super, ça fonctionne.

Interceptons le header et vérifions le token.
Avec Sinatra, on peut intercepter la partie `Authorization` du header grace au helper `env['HTTP_AUTHORIZATION'].

Alors revoyons notre `before` du controller `protected`.

```ruby
# controllers/protected_controller.rb
class ProtectedController < ApplicationController

  before do
    halt 403 unless User.where(api_token: env['HTTP_AUTHORIZATION']).first
  end

end
```

Petit test avec curl

```shell
$ curl -i --request POST 'http://localhost:9292/auth' --data "login=jade&password=kharats01" -H 'Authorization: 052itu87ibS83cUvLMyRsh'
HTTP/1.1 403 Forbidden
Content-Type: text/html;charset=utf-8
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Content-Length: 0

$ curl -i --request POST 'http://localhost:9292/auth' --data "login=jade&password=kharats01" -H 'Authorization: 052itu87ibS83cUvLMyRsg'
HTTP/1.1 200 OK
Content-Type: application/json
X-Content-Type-Options: nosniff
Content-Length: 83

{"token":"1sK4ucvq5pNSauJFbU56Iw","session_expire_date":"2016-01-06T17:37:20.472Z"}
```

YEAH! BABY YEAH!!

Et si on parlait test!
-

Comme vous avez pu le lire jusque là, j'ai fait les tests avec curl. J'ai aussi sauvegardé un projet sous PostMan (ume extension chrome). C'est pas très propre tout ça. Et surtout difficile à transmettre. Je vais donc rajouter les tests dnas le projet après coup. A tous les fans de TDD et/ou BDD, "désolé".

Si j'avais fait du TDD, j'aurais utiliser `minitest` et `cucumber` pour le BDD. C'est donc ces librairies que j'utiliserais pour les tests.
