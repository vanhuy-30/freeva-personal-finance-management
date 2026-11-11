-- BE-P5-E03: daily accepted / corrected counts for category suggestions. No user column. Additive.

CREATE TABLE "CategorySuggestionStat" (
    "day" DATE NOT NULL,
    "surface" VARCHAR(10) NOT NULL,
    "source" VARCHAR(12) NOT NULL,
    "accepted" INTEGER NOT NULL DEFAULT 0,
    "corrected" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "CategorySuggestionStat_pkey" PRIMARY KEY ("day","surface","source")
);
