#######
#
# This file will be run on every deploy, so make sure the changes here are non-destructive
#
#######

SystemSetting.seed(SystemSetting::THRESHOLD_SIGNATURE_COUNT,
                   :description => "The threshold at which petitions are considered for debate in parliament",
                   :initial_value => "100000")

SystemSetting.seed(SystemSetting::GET_AN_MP_SIGNATURE_COUNT,
                   :description => "The threshold at which the creator is emailed to get an MP on board",
                   :initial_value => "40000")
