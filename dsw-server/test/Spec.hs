module Main where

import Control.Lens ((^.))
import qualified Data.Map.Strict as M
import Data.Maybe (fromJust)
import qualified Data.UUID as U
import Test.Hspec

import Constant.Resource
import Database.Connection
import Database.Migration.Development.User.Data.Users
import Integration.Http.Common.HttpClientFactory
import LensesConfig
import Messaging.Connection
import Model.Context.AppContext
import Service.Config.ApplicationConfigService
import Service.Config.BuildInfoConfigService
import Service.User.UserMapper

import Specs.API.BookReference.APISpec
import Specs.API.Branch.APISpec
import Specs.API.Config.APISpec
import Specs.API.Feedback.APISpec
import Specs.API.Info.APISpec
import Specs.API.KnowledgeModel.APISpec
import Specs.API.Level.APISpec
import Specs.API.Metric.APISpec
import Specs.API.MigrationAPISpec
import Specs.API.Organization.APISpec
import Specs.API.Package.APISpec
import Specs.API.Questionnaire.APISpec
import Specs.API.Questionnaire.Migration.APISpec
import Specs.API.Template.APISpec
import Specs.API.Token.APISpec
import Specs.API.Typehint.APISpec
import Specs.API.UserAPISpec
import Specs.API.Version.APISpec
import Specs.Integration.Http.Common.ResponseMapperSpec
import Specs.Integration.Http.Typehint.ResponseMapperSpec
import Specs.Localization.LocaleSpec
import Specs.Model.KnowledgeModel.KnowledgeModelAccessorsSpec
import Specs.Service.Branch.BranchServiceSpec
import Specs.Service.Branch.BranchValidationSpec
import Specs.Service.Document.DocumentServiceSpec
import Specs.Service.Feedback.FeedbackServiceSpec
import Specs.Service.KnowledgeModel.Compilator.CompilatorSpec
import Specs.Service.KnowledgeModel.Compilator.Modifier.ModifierSpec
import Specs.Service.KnowledgeModel.KnowledgeModelFilterSpec
import Specs.Service.Migration.KnowledgeModel.Migrator.MigrationSpec
import qualified
       Specs.Service.Migration.KnowledgeModel.Migrator.SanitizatorSpec
       as KM_SanitizatorSpec
import qualified
       Specs.Service.Migration.Questionnaire.SanitizatorSpec
       as QTN_SanitizatorSpec
import Specs.Service.Organization.OrganizationValidationSpec
import Specs.Service.Package.PackageValidationSpec
import Specs.Service.PublicQuestionnaire.PublicQuestionnaireServiceSpec
import Specs.Service.Report.ReportGeneratorSpec
import Specs.Service.Token.TokenServiceSpec
import Specs.Service.User.UserServiceSpec
import Specs.Util.ListSpec
import Specs.Util.MathSpec
import Specs.Util.TokenSpec
import TestMigration

hLoadConfig fileName loadFn callback = do
  eitherConfig <- loadFn fileName
  case eitherConfig of
    Left error -> do
      putStrLn $ "CONFIG: load failed (" ++ fileName ++ ")"
      putStrLn $ "CONFIG: can't load " ++ fileName ++ ". Maybe the file is missing or not well-formatted"
      putStrLn $ "CONFIG: " ++ show error
    Right config -> do
      putStrLn $ "CONFIG: '" ++ fileName ++ "' loaded"
      callback config

prepareWebApp runCallback = do
  hLoadConfig applicationConfigFileTest getApplicationConfig $ \appConfig ->
    hLoadConfig buildInfoConfigFileTest getBuildInfoConfig $ \buildInfoConfig -> do
      putStrLn $ "ENVIRONMENT: set to " `mappend` (show $ appConfig ^. general . environment)
      dbPool <- createDatabaseConnectionPool appConfig
      putStrLn "DATABASE: connected"
      msgChannel <- createMessagingChannel appConfig
      putStrLn "MESSAGING: connected"
      httpClientManager <- createHttpClientManager appConfig
      putStrLn "HTTP_CLIENT: created"
      let appContext =
            AppContext
            { _appContextAppConfig = appConfig
            , _appContextLocalization = M.empty
            , _appContextBuildInfoConfig = buildInfoConfig
            , _appContextPool = dbPool
            , _appContextMsgChannel = msgChannel
            , _appContextHttpClientManager = httpClientManager
            , _appContextTraceUuid = fromJust (U.fromString "2ed6eb01-e75e-4c63-9d81-7f36d84192c0")
            , _appContextCurrentUser = Just . toDTO $ userAlbert
            }
      runCallback appContext

main :: IO ()
main =
  prepareWebApp
    (\appContext ->
       hspec $ do
         describe "UNIT TESTING" $ do
           describe "INTEGRATION" $ do
             describe "Http" $ do
               describe "Common" $ commonResponseMapperSpec
               describe "Typehint" $ typehintResponseMapperSpec
           describe "MODEL" $ do knowledgeModelAccessorsSpec
           describe "LOCALIZATION" $ localeSpec
           describe "SERVICE" $ do
             describe "Branch" $ do branchValidationSpec
             describe "KnowledgeModel" $ do
               describe "Compilator" $ do
                 describe "Modifier" $ do modifierSpec
                 compilatorSpec
               knowledgeModelFilterSpec
             describe "Migration" $ do
               describe "KnowledgeModel" $ do
                 describe "Migrator" $ do
                   migratorSpec
                   KM_SanitizatorSpec.sanitizatorSpec
               describe "Questionnaire" $ QTN_SanitizatorSpec.sanitizatorSpec
             describe "Organization" $ organizationValidationSpec
             describe "Package" $ packageValidationSpec
             describe "Report" $ reportGeneratorSpec
             describe "Token" $ tokenServiceSpec
           describe "UTIL" $ do
             listSpec
             mathSpec
             tokenSpec
         before (resetDB appContext) $ describe "INTEGRATION TESTING" $ do
           describe "API" $ do
             bookReferenceAPI appContext
             branchAPI appContext
             configAPI appContext
             feedbackAPI appContext
             infoAPI appContext
             knowledgeModelAPI appContext
             levelAPI appContext
             metricAPI appContext
             migratorAPI appContext
             organizationAPI appContext
             packageAPI appContext
             questionnaireAPI appContext
             questionnaireMigrationAPI appContext
             templateAPI appContext
             typehintAPI appContext
             tokenAPI appContext
             userAPI appContext
             versionAPI appContext
           describe "SERVICE" $ do
             branchServiceIntegrationSpec appContext
             feedbackServiceIntegrationSpec appContext
             documentIntegrationSpec appContext
             publicQuestionnaireServiceIntegrationSpec appContext
             userServiceIntegrationSpec appContext)
