import Foundation

public indirect enum PlistEntry: CustomStringConvertible, Equatable {
    case array([PlistEntry?])
    case bool(Bool)
    case data(Data)
    case date(Date)
    case dict([String: PlistEntry?])
    case number(Double)
    case string(String)
    
    public var description: String {
        switch self {
        case .array(let element):
            return "<array \(String(describing: element))>"
        case .bool(let element):
            return "<bool \(String(describing: element))>"
        case .data(let element):
            return "<data \(String(describing: element.count)) bytes>"
        case .date(let element):
            return "<date \(String(describing: element))>"
        case .dict(let element):
            return "<dict \(String(describing: element))>"
        case .number(let element):
            return "<number \(String(describing: element))>"
        case .string(let element):
            return "<string \(String(describing: element))>"
        }
    }
}
