open Fake.IO.Globbing
#r "paket:
nuget Fake.Core.Target
nuget Fake.IO.Zip //"
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
  ++ "LICENSE"
  ++ "**/*.txt"
  ++ "**/*.xml"
  ++ "**/*.md"
  -- "**.fake/**/*"
  -- "FarmingPartyTemplates.lua"
  -- "FarmingParty.lua"
  |> GlobbingPattern.setBaseDir "./"
  |> Shell.copyFilesWithSubFolder "build/FarmingParty/"
)

Target.create "Deploy" (fun p ->
  (sprintf "farming-party-%s.zip" p.Context.Arguments.Head, !! "build/FarmingParty/**")
  ||> Zip.zip "build/"
)

Target.create "Default" ignore

// Dependencies
open Fake.Core.TargetOperators

"Clean"
  ==> "Copy"
  ==> "Default"
  ==> "Deploy"

// start build
Target.runOrDefaultWithArguments "Default"