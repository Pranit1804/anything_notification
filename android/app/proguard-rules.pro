# Room (used by WorkManager) creates its generated database class by
# reflection through a no-argument constructor. R8's full mode removes that
# constructor unless it is kept, which crashes the app at startup in release
# builds ("NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init>").
-keep class * extends androidx.room.RoomDatabase { <init>(); }
