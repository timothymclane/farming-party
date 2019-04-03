open Fake.IO.Globbing
#r "paket:
nuget Fake.Core.Target //"
#load "./.fake/build.fsx/intellisense.fsx"

open Fake.Core
open Fake.IO
open Fake.IO.Globbing.Operators 

// Properties
let buildDir = "./build/"

// Targets
Target.create "Clean" (fun _ ->
  Shell.cleanDir buildDir
)

Target.create "Copy" (fun _ -> 
  !! "**/*.lua"
  ++ "**/*.txt"
  ++ "**/*.xml"
  -- "**.fake/**/*"
  -- "FarmingPartyTemplates.lua"
  -- "FarmingParty.lua"
  |> GlobbingPattern.setBaseDir "./"
  |> Shell.copyFilesWithSubFolder "build/FarmingParty/"
)

Target.create "Default" ignore

// Dependencies
open Fake.Core.TargetOperators

"Clean"
  ==> "Copy"
  ==> "Default"

// start build
Target.runOrDefault "Default"