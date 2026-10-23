# Room 2.2.5 (pulled in by WorkManager via the ads SDK) only keeps the
# database class, and R8 full mode then drops the generated constructor that
# Room creates by reflection → "Failed to create an instance of
# androidx.work.impl.WorkDatabase" at launch (D-036). Keep it.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
