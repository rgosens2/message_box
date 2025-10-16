// swift-tools-version:5.7.2
import PackageDescription

let package = Package(
  name: "MyBoxes",
  targets: [ .executableTarget( 
    name: "mb7", 
    path: ".", // root folder 
    exclude: ["Package.swift"], // exclude itself 
    sources: ["."], // include all Swift files automatically 
    publicHeadersPath: nil ) 
  ] 
)