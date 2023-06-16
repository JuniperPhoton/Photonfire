import Foundation

@attached(peer, names: arbitrary)
public macro PhotonfireService() = #externalMacro(module: "PhotonfireMacros",
                                                  type: "PhotonfireServiceMacro")

@attached(member)
public macro PhotonfireGet(path: String) = #externalMacro(module: "PhotonfireMacros",
                                                          type: "PhotonfireGetMacro")
