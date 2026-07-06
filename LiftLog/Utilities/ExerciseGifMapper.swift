import Foundation

/// Maps exercise names to animated GIF URLs from the free-exercise-db CloudFront CDN.
/// Falls back gracefully to nil (caller shows SF Symbol placeholder).
enum ExerciseGifMapper {
    private static let base = "https://d205bpvrqc9yn1.cloudfront.net"

    private static let ids: [String: String] = [
        // Bodyweight
        "Push-up":                  "0671",
        "Pull-up":                  "0651",
        "Squat":                    "0810",
        "Dip":                      "0239",
        "Plank":                    "0570",
        "Burpee":                   "0107",
        "Chin-up":                  "0172",
        "Lunge":                    "0482",
        "Glute Bridge":             "0334",
        "Mountain Climber":         "0519",
        // Weights
        "Bench Press":              "0024",
        "Dumbbell Curl":            "0241",
        "Romanian Deadlift":        "0694",
        "Overhead Press":           "0531",
        "Barbell Row":              "0027",
        "Lat Pulldown":             "0449",
        "Dumbbell Row":             "0254",
        "Lateral Raise":            "0453",
        "Tricep Pushdown":          "0922",
        "Incline Bench Press":      "0373",
        "Dumbbell Fly":             "0260",
        "Cable Fly":                "0115",
        "Calf Raise":               "0143",
        "Leg Press":                "0462",
        "Leg Extension":            "0458",
        "Leg Curl":                 "0456",
        "Face Pull":                "0308",
        // Powerlifting
        "Back Squat":               "0031",
        "Conventional Deadlift":    "0230",
        "Paused Bench Press":       "0024",
        "Sumo Deadlift":            "0855",
        "Front Squat":              "0322",
        // CrossFit
        "Thruster":                 "0902",
        "Kettlebell Swing":         "0441",
        "Box Jump":                 "0095",
        "Box Squat":                "0096",
        "Barbell Back Squat":       "0031",
        "Clean and Jerk":           "0179",
        "Snatch":                   "0807",
    ]

    static func url(for exerciseName: String) -> URL? {
        guard let id = ids[exerciseName] else { return nil }
        return URL(string: "\(base)/\(id).gif")
    }
}
