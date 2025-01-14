//
//  NetworkRouter.swift
//  F1TV
//
//  Created by Noah Fetz on 24.10.20.
//

import Foundation

class NetworkRouter {
    var decoder: JSONDecoder!
    var encoder: JSONEncoder!
    var session: URLSession!
    
    static let instance = NetworkRouter()
    
    init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.session = URLSession(configuration: self.getURLSessionConfiguration())
    }
    
    /*func getDateFormatter() -> DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return df
    }*/

    
    func getURLSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = ["User-Agent" : "RaceControl"]
        return configuration
    }
    
    func handleFailure(error: APIError) {
        print("Error occured: \(error.localizedDescription)")
        /*DispatchQueue.main.async {
            switch error {
            case .authenticationError:
                UserInteractionHelper.instance.showError(message: NSLocalizedString("credentials_invalid", comment: ""))
            default:
                UserInteractionHelper.instance.showError(message: error.localizedDescription)
            }
        }*/
    }
    
    func authRequest(authRequest: AuthRequestDto, completion: @escaping(Result<AuthResultDto, APIError>) -> Void) {
        var request = RequestHelper.createCustomRequest(url: ConstantsUtil.authenticateUrl, method: "POST")
        request.setValue(ConstantsUtil.apiKey, forHTTPHeaderField: "apikey")
        
        do{
            let data = try self.encoder.encode(authRequest)
            print(String(data: data, encoding: .utf8)!)
            
            request.httpBody = data
        }catch{
            print("Error occured while encoding")
            completion(.failure(.encodingError))
        }
        
        let task = self.session.dataTask(with: request, completionHandler: {
            data, response, error in
            if(error != nil) {
                completion(.failure(.otherError))
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print(response!)
                if(httpStatus.statusCode == 401) {
                    completion(.failure(.authenticationError))
                    return
                }
                completion(.failure(.responseError))
                return
            }
            let requestResult: AuthResultDto
            do {
//                print(String(data: data!,encoding: .utf8)!)
                requestResult = try self.decoder.decode(AuthResultDto.self, from: data!)
                completion(.success(requestResult))
            } catch {
                completion(.failure(.decodingError))
                return
            }
        })
        task.resume()
    }
    
    func tokenRequest(tokenRequest: TokenRequestDto, completion: @escaping(Result<TokenResultDto, APIError>) -> Void) {
        var request = RequestHelper.createCustomRequest(url: ConstantsUtil.tokenUrl, method: "POST")
        
        do{
            let data = try self.encoder.encode(tokenRequest)
            print(String(data: data, encoding: .utf8)!)
            
            request.httpBody = data
        }catch{
            print("Error occured while encoding")
            completion(.failure(.encodingError))
        }
        
        let task = self.session.dataTask(with: request, completionHandler: {
            data, response, error in
            if(error != nil) {
                completion(.failure(.otherError))
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 201 {
                print("statusCode should be 201, but is \(httpStatus.statusCode)")
                print(response!)
                if(httpStatus.statusCode == 401) {
                    completion(.failure(.authenticationError))
                    return
                }
                completion(.failure(.responseError))
                return
            }
            let requestResult: TokenResultDto
            do {
//                print(String(data: data!,encoding: .utf8)!)
                requestResult = try self.decoder.decode(TokenResultDto.self, from: data!)
                completion(.success(requestResult))
            } catch {
                completion(.failure(.decodingError))
                return
            }
        })
        task.resume()
    }
    
    func getContentPageLookup(pageUri: String, completion: @escaping(Result<ApiResponseDto, APIError>) -> Void) {
        let request = RequestHelper.createRequestWithoutAuthentication(restService: pageUri, method: "GET")
        let task = self.session.dataTask(with: request, completionHandler: {
            data, response, error in
            if(error != nil) {
                completion(.failure(.otherError))
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print(response!)
                if(httpStatus.statusCode == 401) {
                    completion(.failure(.authenticationError))
                    return
                }
                completion(.failure(.responseError))
                return
            }
            let requestResult: ApiResponseDto
            do {
//                print(String(data: data!,encoding: .utf8)!)
                requestResult = try self.decoder.decode(ApiResponseDto.self, from: data!)
                completion(.success(requestResult))
            } /*catch {
                completion(.failure(.decodingError))
                return
            }*/
            
            catch let DecodingError.dataCorrupted(context) {
                print(context)
            } catch let DecodingError.keyNotFound(key, context) {
                print("Key '\(key)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch let DecodingError.valueNotFound(value, context) {
                print("Value '\(value)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch let DecodingError.typeMismatch(type, context)  {
                print("Type '\(type)' mismatch:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch {
                print("error: ", error)
            }
        })
        task.resume()
    }
    
    func getContentVideo(videoId: String, completion: @escaping(Result<ApiResponseDto, APIError>) -> Void) {
        let request = RequestHelper.createRequestWithoutAuthentication(restService: "/2.0/R/" + NSLocalizedString("api_endpoing_language_id", comment: "") + "/BIG_SCREEN_HLS/ALL/CONTENT/VIDEO/" + videoId + "/F1_TV_Pro_Annual/2", method: "GET")
        let task = self.session.dataTask(with: request, completionHandler: {
            data, response, error in
            if(error != nil) {
                completion(.failure(.otherError))
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print(response!)
                if(httpStatus.statusCode == 401) {
                    completion(.failure(.authenticationError))
                    return
                }
                completion(.failure(.responseError))
                return
            }
            let requestResult: ApiResponseDto
            do {
//                print(String(data: data!,encoding: .utf8)!)
                requestResult = try self.decoder.decode(ApiResponseDto.self, from: data!)
                completion(.success(requestResult))
            } /*catch {
                completion(.failure(.decodingError))
                return
            }*/
            
            catch let DecodingError.dataCorrupted(context) {
                print(context)
            } catch let DecodingError.keyNotFound(key, context) {
                print("Key '\(key)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch let DecodingError.valueNotFound(value, context) {
                print("Value '\(value)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch let DecodingError.typeMismatch(type, context)  {
                print("Type '\(type)' mismatch:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch {
                print("error: ", error)
            }
        })
        task.resume()
    }
    
    func getStreamEntitlement(contentId: String, completion: @escaping(Result<StreamEntitlementResultDto, APIError>) -> Void) {
        var request = RequestHelper.createRequestWithoutAuthentication(restService: "/1.0/R/" + NSLocalizedString("api_endpoing_language_id", comment: "") + "/BIG_SCREEN_HLS/ALL/" + contentId, method: "GET")
        request.setValue(CredentialHelper.getUserInfo().authData.subscriptionToken, forHTTPHeaderField: "ascendontoken")
        let task = self.session.dataTask(with: request, completionHandler: {
            data, response, error in
            if(error != nil) {
                completion(.failure(.otherError))
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print(response!)
                if(httpStatus.statusCode == 401) {
                    completion(.failure(.authenticationError))
                    return
                }
                completion(.failure(.responseError))
                return
            }
            let requestResult: StreamEntitlementResultDto
            do {
//                print(String(data: data!,encoding: .utf8)!)
                requestResult = try self.decoder.decode(StreamEntitlementResultDto.self, from: data!)
                completion(.success(requestResult))
            } catch {
                completion(.failure(.decodingError))
                return
            }
        })
        task.resume()
    }
}

enum APIError: Error {
    case authenticationError
    case responseError
    case decodingError
    case encodingError
    case otherError
}
