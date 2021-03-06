module Specs.Service.Report.ReportGeneratorSpec where

import Control.Lens ((^.))
import Test.Hspec

import Database.Migration.Development.KnowledgeModel.Data.Chapters
import Database.Migration.Development.KnowledgeModel.Data.KnowledgeModels
import Database.Migration.Development.Metric.Data.Metrics
import Database.Migration.Development.Questionnaire.Data.Questionnaires
import Database.Migration.Development.Report.Data.Reports
import LensesConfig
import Service.Report.ReportGenerator

reportGeneratorSpec =
  describe "Report Generator" $ do
    createReportTest False 1 chapter1 report1_ch1_full_disabled_levels
    createReportTest False 2 chapter2 report1_ch2_full_disabled_levels
    createReportTest False 3 chapter3 report1_ch3_full_disabled_levels
    createReportTest True 1 chapter1 report1_ch1_full
    createReportTest True 2 chapter2 report1_ch2_full
    createReportTest True 3 chapter3 report1_ch3_full

createReportTest levelsEnabled number chapter expectation =
  it ("generateReport for chapter" ++ show number ++ " should work") $
    -- GIVEN: Prepare
   do
    let requiredLevel = 1
    let metrics = [metricF, metricA, metricI, metricR, metricG, metricO]
    let km = km1WithQ4
    let rs = questionnaire1 ^. replies
    -- WHEN:
    let result = computeChapterReport levelsEnabled requiredLevel metrics km rs chapter
    -- THEN
    result `shouldBe` expectation
