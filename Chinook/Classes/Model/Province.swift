//
//  Province.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-06.
//

import Foundation

public struct Province: Hashable, Sendable {
    public var abbreviation: String
    public var nameEn: String
    public var nameFr: String
    
    public var name: String {
        return NSLocale.language == .french ? nameFr : nameEn
    }
    
    public init(abbreviation: String, nameEn: String, nameFr: String) {
        self.abbreviation = abbreviation
        self.nameEn = nameEn
        self.nameFr = nameFr
    }
    
    public static func forCode(_ code: String) -> Province? {
        switch code.uppercased() {
        case "BC": return Province.britishColumbia
        case "AB": return Province.alberta
        case "SK": return Province.saskatchewan
        case "MB": return Province.manitoba
        case "ON": return Province.ontario
        case "QC": return Province.quebec
        case "NB": return Province.newBrunswick
        case "NS": return Province.novaScotia
        case "PE", "PEI": return Province.priceEdwardIsland
        case "NL": return Province.newfoundlandAndLabrador
        case "NU": return Province.nunavut
        case "NT", "NWT": return Province.northwestTerritories
        case "YT": return Province.yukon
        default: break
        }
        
        return nil
    }
    
    public static let britishColumbia = Province(abbreviation: "BC", nameEn: "British Columbia", nameFr: "Colombie-Britannique")
    public static let alberta = Province(abbreviation: "AB", nameEn: "Alberta", nameFr: "Alberta")
    public static let saskatchewan = Province(abbreviation: "SK", nameEn: "Saskatchewan", nameFr: "Saskatchewan")
    public static let manitoba = Province(abbreviation: "MB", nameEn: "Manitoba", nameFr: "Manitoba")
    public static let ontario = Province(abbreviation: "ON", nameEn: "Ontario", nameFr: "Ontario")
    public static let quebec = Province(abbreviation: "QC", nameEn: "Quebec", nameFr: "Québec")
    public static let newBrunswick = Province(abbreviation: "NB", nameEn: "New Brunswick", nameFr: "Nouveau-Brunswick")
    public static let novaScotia = Province(abbreviation: "NS", nameEn: "Nova Scotia", nameFr: "Nouvelle-Écosse")
    public static let priceEdwardIsland = Province(abbreviation: "PE", nameEn: "Price Edward Island", nameFr: "Île-du-Prince-Édouard")
    public static let newfoundlandAndLabrador = Province(abbreviation: "NL", nameEn: "Newfoundland and Labrador", nameFr: "Terre-Neuve-et-Labrador")
    public static let nunavut = Province(abbreviation: "NU", nameEn: "Nunavut", nameFr: "Nunavut")
    public static let northwestTerritories = Province(abbreviation: "NT", nameEn: "Northwest Territories", nameFr: "Territoires du Nord-Ouest")
    public static let yukon = Province(abbreviation: "YT", nameEn: "Yukon", nameFr: "Yukon")
}
