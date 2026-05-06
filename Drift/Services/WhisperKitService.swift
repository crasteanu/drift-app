import Foundation
import WhisperKit

@MainActor
final class WhisperKitService: ObservableObject {
    @Published var state: ServiceState = .idle
    @Published var downloadProgress: Double = 0

    enum ServiceState {
        case idle
        case downloading
        case ready
        case transcribing
        case error(String)
    }

    private var whisperKit: WhisperKit?

    func prepare() async {
        guard whisperKit == nil else { return }
        state = .downloading

        do {
            let config = WhisperKitConfig(model: "small", verbose: false, prewarm: true, load: true)
            let wk = try await WhisperKit(config)
            whisperKit = wk
            state = .ready
            downloadProgress = 1.0
        } catch {
            state = .error("Model download failed: \(error.localizedDescription)")
        }
    }

    func transcribe(url: URL, language: String = "ro") async throws -> String {
        guard let wk = whisperKit else {
            await prepare()
            guard let wk2 = whisperKit else {
                throw TranscriptionError.notReady
            }
            return try await doTranscribe(wk: wk2, url: url, language: language)
        }
        return try await doTranscribe(wk: wk, url: url, language: language)
    }

    private func doTranscribe(wk: WhisperKit, url: URL, language: String) async throws -> String {
        state = .transcribing
        defer { if case .transcribing = state { state = .ready } }

        var options = DecodingOptions()
        options.language = language == "auto" ? nil : language
        options.task = .transcribe
        options.chunkingStrategy = .vad
        options.initialPrompt = Self.dreamPrompt(for: language)

        let resolvedPath = url.resolvingSymlinksInPath().path(percentEncoded: false)
        let results = try await wk.transcribe(audioPath: resolvedPath, decodeOptions: options)
        return results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }

    private static func dreamPrompt(for language: String) -> String? {
        let prompts: [String: String] = [
            "ro": "Jurnal de vise. Vis, somn, noapte, adormit, trezit, coșmar, personaj, loc, senzație, emoție, frică, bucurie, zbor, fugă, apă, casă, pădure, oraș.",
            "en": "Dream journal. Dream, sleep, night, asleep, awake, nightmare, character, place, feeling, emotion, fear, joy, flying, running, water, house, forest, city.",
            "fr": "Journal de rêves. Rêve, sommeil, nuit, endormi, réveillé, cauchemar, personnage, lieu, sensation, émotion, peur, joie, voler, courir, eau, maison, forêt, ville.",
            "de": "Traumtagebuch. Traum, Schlaf, Nacht, eingeschlafen, aufgewacht, Albtraum, Figur, Ort, Gefühl, Emotion, Angst, Freude, fliegen, laufen, Wasser, Haus, Wald, Stadt.",
            "es": "Diario de sueños. Sueño, dormir, noche, dormido, despertado, pesadilla, personaje, lugar, sensación, emoción, miedo, alegría, volar, correr, agua, casa, bosque, ciudad.",
            "it": "Diario dei sogni. Sogno, sonno, notte, addormentato, svegliato, incubo, personaggio, luogo, sensazione, emozione, paura, gioia, volare, correre, acqua, casa, foresta, città.",
            "pt": "Diário de sonhos. Sonho, sono, noite, adormecido, acordado, pesadelo, personagem, lugar, sensação, emoção, medo, alegria, voar, correr, água, casa, floresta, cidade.",
            "nl": "Droomdagboek. Droom, slaap, nacht, slaap gevallen, wakker geworden, nachtmerrie, personage, plek, gevoel, emotie, angst, vreugde, vliegen, rennen, water, huis, bos, stad.",
            "pl": "Dziennik snów. Sen, spanie, noc, zasnąć, obudzić się, koszmar, postać, miejsce, uczucie, emocja, strach, radość, latać, biegać, woda, dom, las, miasto.",
            "ru": "Дневник снов. Сон, спать, ночь, заснуть, проснуться, кошмар, персонаж, место, ощущение, эмоция, страх, радость, летать, бежать, вода, дом, лес, город.",
            "uk": "Щоденник снів. Сон, спати, ніч, заснути, прокинутися, кошмар, персонаж, місце, відчуття, емоція, страх, радість, літати, бігти, вода, будинок, ліс, місто.",
            "cs": "Deník snů. Sen, spánek, noc, usnout, probudit se, noční mora, postava, místo, pocit, emoce, strach, radost, létat, běžet, voda, dům, les, město.",
            "sk": "Denník snov. Sen, spánok, noc, zaspať, prebudiť sa, nočná mora, postava, miesto, pocit, emócia, strach, radosť, lietať, bežať, voda, dom, les, mesto.",
            "hu": "Álomnapló. Álom, alvás, éjszaka, elaludni, felébredni, rémálom, szereplő, hely, érzés, érzelem, félelem, öröm, repülni, futni, víz, ház, erdő, város.",
            "hr": "Dnevnik snova. San, spavanje, noć, zaspati, probuditi se, noćna mora, lik, mjesto, osjećaj, emocija, strah, radost, letjeti, trčati, voda, kuća, šuma, grad.",
            "sv": "Drömjournalen. Dröm, sömn, natt, somna, vakna, mardröm, karaktär, plats, känsla, emotion, rädsla, glädje, flyga, springa, vatten, hus, skog, stad.",
            "no": "Drømmejournalen. Drøm, søvn, natt, sovne, våkne, mareritt, karakter, sted, følelse, emosjon, frykt, glede, fly, løpe, vann, hus, skog, by.",
            "da": "Drømmejournalen. Drøm, søvn, nat, falde i søvn, vågne, mareridt, karakter, sted, følelse, emotion, frygt, glæde, flyve, løbe, vand, hus, skov, by.",
            "fi": "Unikirja. Uni, nukkuminen, yö, nukahtaa, herätä, painajainen, hahmo, paikka, tunne, emootio, pelko, ilo, lentää, juosta, vesi, talo, metsä, kaupunki.",
            "tr": "Rüya günlüğü. Rüya, uyku, gece, uyumak, uyanmak, kabus, karakter, yer, his, duygu, korku, sevinç, uçmak, koşmak, su, ev, orman, şehir.",
            "ar": "مذكرة الأحلام. حلم، نوم، ليل، نام، استيقظ، كابوس، شخصية، مكان، شعور، عاطفة، خوف، فرح، طيران، جري، ماء، بيت، غابة، مدينة.",
            "he": "יומן חלומות. חלום, שינה, לילה, נרדם, התעורר, סיוט, דמות, מקום, תחושה, רגש, פחד, שמחה, עף, רץ, מים, בית, יער, עיר.",
            "ja": "夢日記。夢、睡眠、夜、眠る、目覚める、悪夢、登場人物、場所、感覚、感情、恐怖、喜び、飛ぶ、走る、水、家、森、街。",
            "zh": "梦境日记。梦、睡眠、夜晚、入睡、醒来、噩梦、人物、地点、感觉、情感、恐惧、喜悦、飞翔、奔跑、水、房子、森林、城市。",
            "ko": "꿈 일기. 꿈, 수면, 밤, 잠들다, 깨어나다, 악몽, 등장인물, 장소, 느낌, 감정, 두려움, 기쁨, 날다, 뛰다, 물, 집, 숲, 도시.",
            "hi": "स्वप्न पत्रिका। सपना, नींद, रात, सो जाना, जागना, बुरा सपना, पात्र, स्थान, अनुभव, भावना, डर, खुशी, उड़ना, दौड़ना, पानी, घर, जंगल, शहर।",
            "id": "Jurnal mimpi. Mimpi, tidur, malam, tertidur, terbangun, mimpi buruk, tokoh, tempat, perasaan, emosi, takut, gembira, terbang, berlari, air, rumah, hutan, kota.",
        ]
        return prompts[language]
    }
}

enum TranscriptionError: LocalizedError {
    case notReady
    var errorDescription: String? { "Transcription model not ready" }
}
