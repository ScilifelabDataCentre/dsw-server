module Database.Migration.User.UserMigration where

import Data.Maybe
import qualified Data.UUID as U

import Api.Resources.User.UserCreateDTO
import Context
import Database.DAO.User.UserDAO
import Service.User.UserService

runMigration context dspConfig logState = do
  logState "MIGRATION (User/User): started"
  deleteUsers context
  createUserWithGivenUuid
    context
    dspConfig
    (fromJust (U.fromString "ec6f8e90-2a91-49ec-aa3f-9eab2267fc66"))
    UserCreateDTO
    { _ucdtoName = "Darth"
    , _ucdtoSurname = "Vader"
    , _ucdtoEmail = "darth.vader@deathstar.com"
    , _ucdtoRole = "ADMIN"
    , _ucdtoPassword = "password"
    }
  createUserWithGivenUuid
    context
    dspConfig
    (fromJust (U.fromString "30d48cf4-8c8a-496f-bafe-585bd238f798"))
    UserCreateDTO
    { _ucdtoName = "Luke"
    , _ucdtoSurname = "Skywalker"
    , _ucdtoEmail = "luke.skywalker@deathstar.com"
    , _ucdtoRole = "DATASTEWARD"
    , _ucdtoPassword = "password"
    }
  createUserWithGivenUuid
    context
    dspConfig
    (fromJust (U.fromString "e1c58e52-0824-4526-8ebe-ec38eec67030"))
    UserCreateDTO
    { _ucdtoName = "John"
    , _ucdtoSurname = "Snow"
    , _ucdtoEmail = "john.snow@gof.com"
    , _ucdtoRole = "RESEARCHER"
    , _ucdtoPassword = "password"
    }
  logState "MIGRATION (User/User): ended"