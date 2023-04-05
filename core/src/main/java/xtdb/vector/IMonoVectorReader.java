package xtdb.vector;

public interface IMonoVectorReader {

    int valueCount();

    boolean readBoolean(int idx);
    byte readByte(int idx);
    short readShort(int idx);
    int readInt(int idx);
    long readLong(int idx);

    float readFloat(int idx);
    double readDouble(int idx);

    Object readObject(int idx);
}
