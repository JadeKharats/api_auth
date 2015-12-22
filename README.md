construire une API micro service auth avec sinatra et rethinkdb

* Identifions les besoins
Nous avons besoin d'identifier notre appelant ou consommateur.
Ce consommateur a besoin de gérer les utilisateurs de notre API.
Ce consommateur a besoin de stocker des données propres à son usage

* Modele
on peut considérer que les consommateurs et les utilisateurs sont le même objet avec des droits différents.

USERS
id:integer
login:string
password:string
salt:string
api_token:string
session_token:string
session_expire_date:datetime
created_at:datetime
updated_at:datetime

Si on considère que nous allons avons besoin de laissé le schema libre d'être modifié (pour répondre à l'un des besoins), le stockage se fera en NoSQL. ici, ce sera RethinkDB

* Les urls

| Verbe  | Urls           | Données                                     | Conditions       | Retour                                     |
| ------ |: -------------:|: ------------------------------------------:|: ---------------:|: ----------------------------------------: |
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

