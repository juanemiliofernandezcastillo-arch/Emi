import 'models.dart';

final List<Exercise> defaultExercises = [
  // --- CHEST ---
  Exercise(
    id: "barbell_bench_press",
    name: "Barbell Bench Press",
    muscleGroup: "Chest",
    equipment: "Barbell",
    instructions: "Lie flat on a bench, grip the barbell slightly wider than shoulder-width, lower the bar to your chest, and push it back up to lock-out."
  ),
  Exercise(
    id: "incline_barbell_bench_press",
    name: "Incline Barbell Bench Press",
    muscleGroup: "Chest",
    equipment: "Barbell",
    instructions: "Set the bench to a 30-45 degree incline. Lower the barbell to your upper chest, and press upwards until arms are extended."
  ),
  Exercise(
    id: "decline_barbell_bench_press",
    name: "Decline Barbell Bench Press",
    muscleGroup: "Chest",
    equipment: "Barbell",
    instructions: "Lie on a decline bench. Lower the barbell to your lower chest, and press up until arms are fully locked."
  ),
  Exercise(
    id: "dumbbell_bench_press",
    name: "Dumbbell Bench Press",
    muscleGroup: "Chest",
    equipment: "Dumbbell",
    instructions: "Lie flat on a bench with a dumbbell in each hand. Press the weights upward, contracting your chest at the top."
  ),
  Exercise(
    id: "incline_dumbbell_press",
    name: "Incline Dumbbell Press",
    muscleGroup: "Chest",
    equipment: "Dumbbell",
    instructions: "Lie on an incline bench with dumbbells. Press the weights up over your chest while keeping shoulders retracted."
  ),
  Exercise(
    id: "dumbbell_chest_fly",
    name: "Dumbbell Chest Fly",
    muscleGroup: "Chest",
    equipment: "Dumbbell",
    instructions: "Lie on a flat bench, hold dumbbells with slightly bent elbows, open arms wide to stretch the chest, and squeeze back up."
  ),
  Exercise(
    id: "chest_dips",
    name: "Chest Dips",
    muscleGroup: "Chest",
    equipment: "Bodyweight",
    instructions: "Lean forward slightly on dip bars, lower yourself until elbows are at a 90-degree angle, then press up dynamically."
  ),
  Exercise(
    id: "cable_crossover",
    name: "Cable Crossover",
    muscleGroup: "Chest",
    equipment: "Cable",
    instructions: "Position pulleys high, grab handles, step forward, and sweep your hands down and inward to meet in front of your waist."
  ),
  Exercise(
    id: "push_up",
    name: "Push-Up",
    muscleGroup: "Chest",
    equipment: "Bodyweight",
    instructions: "Keep your body in a straight line, hands slightly wider than shoulder-width, lower chest to floor, and push back up."
  ),
  Exercise(
    id: "pec_deck_fly",
    name: "Pec Deck Machine Fly",
    muscleGroup: "Chest",
    equipment: "Machine",
    instructions: "Sit with back flat against pad. Squeeze the handles/pads together in front of your chest and return under control."
  ),

  // --- BACK ---
  Exercise(
    id: "conventional_deadlift",
    name: "Barbell Deadlift (Conventional)",
    muscleGroup: "Back",
    equipment: "Barbell",
    instructions: "Stand with feet hip-width. Bend at hips and knees, grab bar, keep back flat, chest up, and pull bar up while driving hips forward."
  ),
  Exercise(
    id: "pull_up",
    name: "Pull-Up",
    muscleGroup: "Back",
    equipment: "Bodyweight",
    instructions: "Hang from a bar with a wide overhand grip. Pull your chest up to the bar, leading with your elbows, then lower slowly."
  ),
  Exercise(
    id: "chin_up",
    name: "Chin-Up",
    muscleGroup: "Back",
    equipment: "Bodyweight",
    instructions: "Hang with an underhand shoulder-width grip. Pull your body up until your chin clears the bar, lowering slowly."
  ),
  Exercise(
    id: "lat_pulldown_wide_grip",
    name: "Lat Pulldown (Wide Grip)",
    muscleGroup: "Back",
    equipment: "Cable",
    instructions: "Sit at a pulldown station, grip the bar wide, pull the bar down to your upper chest while leaning slightly back."
  ),
  Exercise(
    id: "barbell_row",
    name: "Bent-Over Barbell Row",
    muscleGroup: "Back",
    equipment: "Barbell",
    instructions: "Hinge at hips with flat back. Grip barbell, pull the bar to your lower ribcage, squeezing shoulder blades together."
  ),
  Exercise(
    id: "one_arm_dumbbell_row",
    name: "One-Arm Dumbbell Row",
    muscleGroup: "Back",
    equipment: "Dumbbell",
    instructions: "Support knee and hand on a bench. Pull the dumbbell to your hip, keeping your elbow tucked, and return under control."
  ),
  Exercise(
    id: "seated_cable_row",
    name: "Seated Cable Row",
    muscleGroup: "Back",
    equipment: "Cable",
    instructions: "Sit with knees slightly bent. Pull the handle toward your lower abdomen, retracting and squeezing your upper back."
  ),
  Exercise(
    id: "t_bar_row",
    name: "T-Bar Row",
    muscleGroup: "Back",
    equipment: "Barbell",
    instructions: "Straddle a landmine barbell. Grab the handles, bend at hips, and row the weight to your chest keeping chest up."
  ),
  Exercise(
    id: "back_extensions",
    name: "Hyperextension (Back Extension)",
    muscleGroup: "Back",
    equipment: "Machine",
    instructions: "Secure yourself in the bench. Hinge at the waist, lower your torso, then raise back up until your spine is aligned."
  ),
  Exercise(
    id: "face_pull",
    name: "Cable Face Pull",
    muscleGroup: "Back",
    equipment: "Cable",
    instructions: "Hold rope attachment with thumbs facing back. Pull toward your face, flaring elbows out and squeezing rear delts."
  ),

  // --- LEGS ---
  Exercise(
    id: "barbell_back_squat",
    name: "Barbell Back Squat",
    muscleGroup: "Legs",
    equipment: "Barbell",
    instructions: "Rest bar on upper traps. Squat down by sending hips back, keeping chest up, until thighs are parallel to floor or lower, then stand."
  ),
  Exercise(
    id: "barbell_front_squat",
    name: "Barbell Front Squat",
    muscleGroup: "Legs",
    equipment: "Barbell",
    instructions: "Rest bar on front of shoulders. Keep elbows high, squat down deeply keeping torso upright, and drive back up."
  ),
  Exercise(
    id: "leg_press",
    name: "Leg Press",
    muscleGroup: "Legs",
    equipment: "Machine",
    instructions: "Sit in leg press machine, place feet shoulder-width, unlock sled, lower under control to 90 degrees, then press up (do not lock knees)."
  ),
  Exercise(
    id: "romanian_deadlift_barbell",
    name: "Barbell Romanian Deadlift",
    muscleGroup: "Legs",
    equipment: "Barbell",
    instructions: "Stand tall. Slide barbell down your thighs by pushing hips back, keeping knees stiff but not locked, feel stretch, squeeze glutes to stand."
  ),
  Exercise(
    id: "bulgarian_split_squat",
    name: "Dumbbell Bulgarian Split Squat",
    muscleGroup: "Legs",
    equipment: "Dumbbell",
    instructions: "Place one foot behind you on a bench. Hold dumbbells, lower hips until back knee is near floor, and drive through front heel."
  ),
  Exercise(
    id: "goblet_squat",
    name: "Dumbbell Goblet Squat",
    muscleGroup: "Legs",
    equipment: "Dumbbell",
    instructions: "Hold a dumbbell vertically under your chin. Squat deeply, keeping weight in heels and spine neutral."
  ),
  Exercise(
    id: "leg_extension",
    name: "Leg Extension",
    muscleGroup: "Legs",
    equipment: "Machine",
    instructions: "Sit on the machine. Extend your legs fully, hold for a split second, and return slowly to starting position."
  ),
  Exercise(
    id: "lying_leg_curl",
    name: "Lying Leg Curl",
    muscleGroup: "Legs",
    equipment: "Machine",
    instructions: "Lie face down, secure ankles under roller. Curl the pad toward your glutes, squeeze, and lower slowly."
  ),
  Exercise(
    id: "hip_thrust_barbell",
    name: "Barbell Hip Thrust",
    muscleGroup: "Legs",
    equipment: "Barbell",
    instructions: "Rest upper back on a bench, barbell on hips. Drive hips vertically up, squeezing glutes hard at the top."
  ),
  Exercise(
    id: "standing_calf_raise",
    name: "Standing Calf Raise",
    muscleGroup: "Legs",
    equipment: "Machine",
    instructions: "Adjust shoulder pads. Lower heels to full stretch, then press up on balls of feet, squeezing calves."
  ),
  Exercise(
    id: "dumbbell_lunge",
    name: "Dumbbell Lunge",
    muscleGroup: "Legs",
    equipment: "Dumbbell",
    instructions: "Hold dumbbells. Step forward, lower until back knee is near the floor, then push back to starting position."
  ),

  // --- SHOULDERS ---
  Exercise(
    id: "overhead_press_barbell",
    name: "Barbell Overhead Press",
    muscleGroup: "Shoulders",
    equipment: "Barbell",
    instructions: "Stand tall. Clean bar to shoulders, press bar vertically overhead, tucking head forward as bar clears face."
  ),
  Exercise(
    id: "dumbbell_shoulder_press",
    name: "Seated Dumbbell Shoulder Press",
    muscleGroup: "Shoulders",
    equipment: "Dumbbell",
    instructions: "Sit on a bench, dumbbells at shoulder level. Press dumbbells vertically, bringing them close at the top."
  ),
  Exercise(
    id: "lateral_raise_dumbbell",
    name: "Dumbbell Lateral Raise",
    muscleGroup: "Shoulders",
    equipment: "Dumbbell",
    instructions: "Stand holding dumbbells. Raise arms out to the sides until horizontal, keeping a slight bend in elbows."
  ),
  Exercise(
    id: "lateral_raise_cable",
    name: "Cable Lateral Raise",
    muscleGroup: "Shoulders",
    equipment: "Cable",
    instructions: "Stand next to a low pulley. Pull the cable across your body and upward to horizontal to keep tension."
  ),
  Exercise(
    id: "rear_delt_fly_dumbbell",
    name: "Dumbbell Rear Delt Fly",
    muscleGroup: "Shoulders",
    equipment: "Dumbbell",
    instructions: "Bend over at the waist, back flat. Raise dumbbells out to the sides, squeezing your rear deltoids."
  ),
  Exercise(
    id: "dumbbell_front_raise",
    name: "Dumbbell Front Raise",
    muscleGroup: "Shoulders",
    equipment: "Dumbbell",
    instructions: "Stand with dumbbells. Raise one dumbbell at a time straight in front of you to shoulder level."
  ),
  Exercise(
    id: "barbell_shrug",
    name: "Barbell Shrug",
    muscleGroup: "Shoulders",
    equipment: "Barbell",
    instructions: "Hold barbell in front of thighs. Elevate shoulders straight up toward ears, hold, and lower slowly."
  ),

  // --- ARMS (BICEPS) ---
  Exercise(
    id: "barbell_curl",
    name: "Barbell Bicep Curl",
    muscleGroup: "Arms",
    equipment: "Barbell",
    instructions: "Stand holding a barbell with underhand grip. Curl the bar up, keeping elbows tucked, and squeeze biceps."
  ),
  Exercise(
    id: "dumbbell_bicep_curl",
    name: "Dumbbell Bicep Curl",
    muscleGroup: "Arms",
    equipment: "Dumbbell",
    instructions: "Stand holding dumbbells. Curl one side up, rotating palm upward (supinating) at the top, then lower."
  ),
  Exercise(
    id: "hammer_curl",
    name: "Dumbbell Hammer Curl",
    muscleGroup: "Arms",
    equipment: "Dumbbell",
    instructions: "Hold dumbbells with neutral (palms facing each other) grip. Curl upward, maintaining neutral hand position."
  ),
  Exercise(
    id: "incline_dumbbell_curl",
    name: "Incline Dumbbell Curl",
    muscleGroup: "Arms",
    equipment: "Dumbbell",
    instructions: "Sit on incline bench. Let arms hang back, curl dumbbells up without flaring elbows forward."
  ),
  Exercise(
    id: "cable_bicep_curl",
    name: "Cable Bicep Curl",
    muscleGroup: "Arms",
    equipment: "Cable",
    instructions: "Stand facing a low cable. Grip bar, curl upward, maintaining constant tension from the cable."
  ),

  // --- ARMS (TRICEPS) ---
  Exercise(
    id: "tricep_pushdown_cable",
    name: "Cable Tricep Pushdown",
    muscleGroup: "Arms",
    equipment: "Cable",
    instructions: "Grip rope or bar attachment at chest height. Keep elbows tucked to sides, extend arms downward, and squeeze triceps."
  ),
  Exercise(
    id: "skull_crusher_ez_bar",
    name: "EZ Bar Skull Crusher",
    muscleGroup: "Arms",
    equipment: "Barbell",
    instructions: "Lie on a flat bench. Hold EZ bar above chest, bend at elbows to lower bar toward forehead, then extend arms."
  ),
  Exercise(
    id: "dumbbell_overhead_tricep_extension",
    name: "Dumbbell Overhead Tricep Extension",
    muscleGroup: "Arms",
    equipment: "Dumbbell",
    instructions: "Hold a dumbbell with both hands overhead. Lower weight behind your head, then extend elbows to push up."
  ),
  Exercise(
    id: "close_grip_bench_press",
    name: "Close-Grip Barbell Bench Press",
    muscleGroup: "Arms",
    equipment: "Barbell",
    instructions: "Lie flat on a bench. Grip bar shoulder-width, lower bar to mid-chest keeping elbows close to body, and press up."
  ),

  // --- CORE ---
  Exercise(
    id: "plank",
    name: "Forearm Plank",
    muscleGroup: "Core",
    equipment: "Bodyweight",
    instructions: "Hold a forearm plank position. Keep body in a straight line, core braced, hips aligned (do not let hips sag)."
  ),
  Exercise(
    id: "hanging_leg_raise",
    name: "Hanging Leg Raise",
    muscleGroup: "Core",
    equipment: "Bodyweight",
    instructions: "Hang from a pull-up bar. Keep legs straight and raise them up until they are parallel to the floor, lowering slowly."
  ),
  Exercise(
    id: "ab_wheel_rollout",
    name: "Ab Wheel Rollout",
    muscleGroup: "Core",
    equipment: "Bodyweight",
    instructions: "Kneel with hands on ab wheel. Roll wheel forward, extending body as far as possible without arching lower back, pull back."
  ),
  Exercise(
    id: "cable_crunch",
    name: "Cable Kneeling Crunch",
    muscleGroup: "Core",
    equipment: "Cable",
    instructions: "Kneel facing cable machine with rope attachment. Hold rope by ears, crunch down bringing elbows to thighs, squeezing abs."
  ),
  Exercise(
    id: "russian_twist",
    name: "Russian Twist",
    muscleGroup: "Core",
    equipment: "Bodyweight",
    instructions: "Sit on floor, knees bent, feet slightly elevated. Twist torso from side to side, optionally holding a weight."
  )
];

final List<String> muscleGroups = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Core"];
final List<String> equipmentTypes = ["Barbell", "Dumbbell", "Cable", "Machine", "Bodyweight"];
