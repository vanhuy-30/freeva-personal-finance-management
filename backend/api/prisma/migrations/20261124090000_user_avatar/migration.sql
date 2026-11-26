-- Profile photo: one small JPEG per user (the app sends it already resized). Kept out of "User" so ordinary user
-- reads never load the bytes.
CREATE TABLE "UserAvatar" (
  "userId" UUID NOT NULL,
  "image" BYTEA NOT NULL,
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "UserAvatar_pkey" PRIMARY KEY ("userId"),
  CONSTRAINT "UserAvatar_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "UserAvatar_size" CHECK (octet_length("image") BETWEEN 1 AND 65536)
);
