//! Module that contains extension Traits that extend the functionality of commonly used  structs like [`ByteBuffer`]

use bytebuffer::ByteBuffer;
use std::{error::Error, string::FromUtf8Error};
use thiserror::Error;

/// Extension methods for [ByteBuffer] to add support
/// for reading/writing more types.
pub trait ByteBufferExt {
    // GENERAL

    fn new_little_endian() -> ByteBuffer {
        let mut buffer = ByteBuffer::new();
        buffer.set_endian(bytebuffer::Endian::LittleEndian);
        buffer
    }

    // WRITE

    /// Writes a string with a length representable by a u8.
    /// The string is encoded in utf-8.
    fn write_str_u8_len(&mut self, string: &str) -> Result<(), ByteBufferExtError>;

    /// Writes a string with a length representable by a u16.
    /// The string is encoded in utf-8.
    fn write_str_u16_len(&mut self, string: &str) -> Result<(), ByteBufferExtError>;

    /// Writes a string with a length representable by a u32.
    /// The string is encoded in utf-8.
    fn write_str_u32_len(&mut self, string: &str) -> Result<(), ByteBufferExtError>;

    /// Writes an Option<T> types
    fn write_option<T>(&mut self, option: &Option<T>, write: fn(&mut ByteBuffer, &T));

    /// Writes a bool
    fn write_bool(&mut self, value: bool);

    // READ

    /// Reads a string with a length representable by a u8.
    /// The string is read as a utf-8 encoded string.
    fn read_str_u8_len(&mut self) -> Result<String, ByteBufferExtError>;

    /// Reads a string with a length representable by a u16.
    /// The string is read as a utf-8 encoded string.
    fn read_str_u16_len(&mut self) -> Result<String, ByteBufferExtError>;

    /// Reads a string with a length representable by a u32.
    /// The string is read as a utf-8 encoded string.
    fn read_str_u32_len(&mut self) -> Result<String, ByteBufferExtError>;

    /// Reads an Option<T> types
    fn read_option<T>(
        &mut self,
        read: fn(&mut ByteBuffer) -> T,
    ) -> Result<Option<T>, ByteBufferExtError>;

    /// Reads a bool
    fn read_bool(&mut self) -> Result<bool, ByteBufferExtError>;
}

impl ByteBufferExt for ByteBuffer {
    fn write_str_u8_len(&mut self, string: &str) -> Result<(), ByteBufferExtError> {
        let bytes = string.as_bytes();
        self.write_u8(
            bytes
                .len()
                .try_into()
                .map_err(|_| ByteBufferExtError::StrLenOverflow(u8::MAX.into()))?,
        );
        self.write_bytes(string.as_bytes());
        Ok(())
    }

    fn write_str_u16_len(&mut self, string: &str) -> Result<(), ByteBufferExtError> {
        let bytes = string.as_bytes();
        self.write_u16(
            bytes
                .len()
                .try_into()
                .map_err(|_| ByteBufferExtError::StrLenOverflow(u16::MAX.into()))?,
        );
        self.write_bytes(string.as_bytes());
        Ok(())
    }

    fn write_str_u32_len(&mut self, string: &str) -> Result<(), ByteBufferExtError> {
        let bytes = string.as_bytes();
        self.write_u32(
            bytes
                .len()
                .try_into()
                .map_err(|_| ByteBufferExtError::StrLenOverflow(u32::MAX.into()))?,
        );
        self.write_bytes(string.as_bytes());
        Ok(())
    }

    fn read_str_u8_len(&mut self) -> Result<String, ByteBufferExtError> {
        let len = self.read_u8()?;
        let bytes = self.read_bytes(len.into())?;
        let result = String::from_utf8(bytes)?;
        Ok(result)
    }

    fn read_str_u16_len(&mut self) -> Result<String, ByteBufferExtError> {
        let len = self.read_u16()?;
        let bytes = self.read_bytes(len.into())?;
        let result = String::from_utf8(bytes)?;
        Ok(result)
    }

    fn read_str_u32_len(&mut self) -> Result<String, ByteBufferExtError> {
        let len = self.read_u32()?;
        let bytes = self.read_bytes(
            len.try_into()
                .map_err(|_| ByteBufferExtError::U32UnsupportedUSize())?,
        )?;
        let result = String::from_utf8(bytes)?;
        Ok(result)
    }

    fn write_option<T>(&mut self, option: &Option<T>, write: fn(&mut ByteBuffer, &T)) {
        if let Some(value) = option.as_ref() {
            self.write_u8(1);
            write(self, value);
        } else {
            self.write_u8(0);
        }
    }

    fn read_option<T>(
        &mut self,
        read: fn(&mut ByteBuffer) -> T,
    ) -> Result<Option<T>, ByteBufferExtError> {
        let exists = self.read_u8()?;
        if exists == 1 {
            Ok(Some(read(self)))
        } else {
            Ok(None)
        }
    }

    fn write_bool(&mut self, value: bool) {
        self.write_u8(match value {
            true => 1,
            false => 0,
        })
    }

    fn read_bool(&mut self) -> Result<bool, ByteBufferExtError> {
        Ok(self.read_u8()? == 1)
    }
}

#[derive(Error, Debug)]
pub enum ByteBufferExtError {
    #[error("io error: {0}")]
    IOError(std::io::Error),
    #[error("vec length must be <= {0}")]
    VecLenOverflow(u32),
    #[error("str byte length must be <= {0}")]
    StrLenOverflow(u32),
    #[error("error converting byte array to utf-8 str: {0}")]
    StrConversionError(FromUtf8Error),
    #[error("u32 > usize on this platform")]
    U32UnsupportedUSize(),
    #[error("error: {0}")]
    Error(Box<dyn Error>),
}

impl From<std::io::Error> for ByteBufferExtError {
    fn from(value: std::io::Error) -> Self {
        ByteBufferExtError::IOError(value)
    }
}

impl From<FromUtf8Error> for ByteBufferExtError {
    fn from(value: FromUtf8Error) -> Self {
        ByteBufferExtError::StrConversionError(value)
    }
}
