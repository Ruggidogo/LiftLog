import Foundation

/// Maps exercise names to animated GIF URLs from the ExerciseDB CDN.
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
        "Sit-up":                   "0793",
        "Crunch":                   "0211",
        "Jumping Jack":             "0428",
        "Pike Push-up":             "0560",
        "Diamond Push-up":          "0234",
        "Tricep Dip":               "0239",
        "Inverted Row":             "0388",
        "Step-up":                  "0838",
        "Wall Sit":                 "0960",
        "Hip Thrust":               "0363",
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
        "Hammer Curl":              "0351",
        "Arnold Press":             "0012",
        "Seated Row":               "0747",
        "Cable Row":                "0120",
        "Tricep Extension":         "0907",
        "Skull Crusher":            "0799",
        "Preacher Curl":            "0613",
        "Concentration Curl":       "0193",
        "Front Raise":              "0328",
        "Upright Row":              "0946",
        "Shrug":                    "0783",
        "Good Morning":             "0338",
        "Hip Abduction":            "0362",
        "Cable Kickback":           "0128",
        "Goblet Squat":             "0335",
        "Sumo Squat":               "0862",
        "Bulgarian Split Squat":    "0108",
        "Walking Lunge":            "0958",
        "Reverse Lunge":            "0685",
        // Powerlifting
        "Back Squat":               "0031",
        "Conventional Deadlift":    "0230",
        "Paused Bench Press":       "0024",
        "Sumo Deadlift":            "0855",
        "Front Squat":              "0322",
        "Box Squat":                "0096",
        // CrossFit
        "Thruster":                 "0902",
        "Kettlebell Swing":         "0441",
        "Box Jump":                 "0095",
        "Barbell Back Squat":       "0031",
        "Clean and Jerk":           "0179",
        "Snatch":                   "0807",
        "Rope Jump":                "0703",
        "Wall Ball":                "0965",
        "Muscle-up":                "0521",
    ]

    static func url(for exerciseName: String) -> URL? {
        guard let id = ids[exerciseName] else { return nil }
        return URL(string: "\(base)/\(id).gif")
    }
}
